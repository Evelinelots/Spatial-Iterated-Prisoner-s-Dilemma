globals
[
  average-fitness
  pen-list
  average-p
  average-q
  Best-strategy
  time
]

Patches-own
[
  p
  q

  p-partner
  q-partner

  cx
  cy

  payoff
  opponents
  partner
  max-payoff-neighbors
  best-neighbor
  worst-player? ;; true if you are the worst player in your neighborhood
  best-player? ;; true if you are the best player in your neighborhood
  update-rule
]

to setup
  clear-all
  set time 0 ;; keeps track of when to switch update strategy
  ask patches
  [
    if update-strategy = "Per patch"
    [
      ifelse strategies-121 = true
      [set update-rule one-of ["Grim-variation" "Wang" "New2"]]
      [set update-rule one-of ["Grim-variation" "Wang" "New1"]]
    ]
  ]

  ;; randomly choose starting strategy of either 121 or 16 strategies
  ifelse strategies-121 = true
  [ask patches [set pcolor (random 121) + 10]]
  [ask patches [set pcolor one-of [lime red blue green orange pink violet magenta gray yellow turquoise cyan sky black 42 brown]]]

  set pen-list ["10" "11" "12" "13" "14" "15" "16" "17" "18" "19"
    "20" "21" "22" "23" "24" "25" "26" "27" "28" "29"
    "30" "31" "32" "33" "34" "35" "36" "37" "38" "39"
    "40" "41" "42" "43" "44" "45" "46" "47" "48" "49"
    "50" "51" "52" "53" "54" "55" "56" "57" "58" "59"
    "60" "61" "62" "63" "64" "65" "66" "67" "68" "69"
    "70" "71" "72" "73" "74" "75" "76" "77" "78" "79"
    "80" "81" "82" "83" "84" "85" "86" "87" "88" "89"
    "90" "91" "92" "93" "94" "95" "96" "97" "98" "99"
    "100" "101" "102" "103" "104" "105" "106" "107" "108" "109"
    "110" "111" "112" "113" "114" "115" "116" "117" "118" "119"
    "120" "121" "122" "123" "124" "125" "126" "127" "128" "129"
    "130" "131"]
  reset-ticks
end


to go ;; all patches play infinite IPD against each of their neighbors

  select-opponents
  ask patches
  [
    set payoff 0
    foreach opponents
    [
      x -> set partner x
      play-IPD
    ]
  ]
  calc-average-fitness
  calc-av-p
  calc-av-q
  update-strategies
  show-best-strategy
  write-file

  if show-best-strat = true [show-best-strategy]
  if big-plot = true [do-plots]

  set time time + 1
  tick
end

to update-strategies
    ;; update strategy according to chosen update rule
  if update-strategy = "Grim" [ask patches [update-strategy-Grim]]
  if update-strategy = "Grim-variation" [ask patches [update-strategy-Grim-variation]]
  if update-strategy = "Wang" [ask patches [update-strategy-Wang]]
  if update-strategy = "New1" [ask patches [update-strategy-proposed-1]]
  if update-strategy = "New2" [ask patches [update-strategy-proposed-2]]

  if update-strategy = "Per patch" ;; update strategy of patch according to patch specific update rule, after period of time, switch randomly to other update rule
  [
   ifelse time = 10
   [
     ask patches
     [
       ifelse strategies-121 = true
       [set update-rule one-of ["Grim-variation" "Wang" "New2"]]
       [set update-rule one-of ["Grim-variation" "Wang" "New1"]]
     ]
     set time 0
   ]
   [
     ask patches
     [
       if update-rule = "Grim-variation" [update-strategy-Grim-variation]
       if update-rule = "Wang" [update-strategy-Wang]
       if strategies-121 = true [if update-rule = "New2" [update-strategy-proposed-2]]
     ]
   ]
  ]
end

to update-strategy-Grim ;; update according to Grim --> copy strategy of best performing neighbor
  set max-payoff-neighbors 0
  let opponents-Grim opponents
  foreach opponents-Grim
  [
    x -> set partner x
    if [payoff] of partner >= max-payoff-neighbors
    [
      set max-payoff-neighbors [payoff] of partner
      set best-neighbor partner
    ]
  ]
  set pcolor [pcolor] of best-neighbor
end

to update-strategy-Grim-variation ;; update according to Grim --> copy strategy of best performing neighbor or stick to strategy if you are the best
  set max-payoff-neighbors 0
  let opponents-Grim-variation opponents
  set opponents-Grim-variation insert-item 1 opponents self
  foreach opponents-Grim-variation
  [
    x -> set partner x
    if [payoff] of partner >= max-payoff-neighbors
    [
      set max-payoff-neighbors [payoff] of partner
      set best-neighbor partner
    ]
  ]
  set pcolor [pcolor] of best-neighbor
end

to update-strategy-Wang ;; update according to Wang et al. (2016)
  ;; randomly choose new strategy when you are have the lowest payoff in your neighborhood

  set worst-player? true
  let threshold 0
  foreach opponents
  [
    x -> set partner x
    if payoff - [payoff] of partner >= threshold  ;;if at least one neighbor has an identifiably lower payoff, stick to strategy
    [
      set worst-player? false ;; stick to strategy
    ]
  ]
  if worst-player? = true
  [
    ifelse strategies-121 = true
    [set pcolor (random 121) + 10]
    [set pcolor one-of [lime red blue green orange pink violet magenta gray yellow turquoise cyan sky black 42 brown]]
  ]
end

to update-strategy-proposed-1 ;; randomly change strategy as soon as you find a better player in neighborhood (when you are not the best)
  foreach opponents
  [
    x -> set partner x
    if [payoff] of partner > payoff
    [
      ifelse strategies-121 = true
      [set pcolor (random 121) + 10]
      [set pcolor one-of [lime red blue green orange pink violet magenta gray yellow turquoise cyan sky black 42 brown]]
      stop
    ]
  ]
end

to update-strategy-proposed-2 ;; if best neighbor is more cooperative than you, become more cooperative (increase p and q by 0.1)
  set max-payoff-neighbors 0
  let threshold 0.2
  foreach opponents
  [
    x -> set partner x
    if [payoff] of partner >= max-payoff-neighbors
    [
      set max-payoff-neighbors [payoff] of partner
      set best-neighbor partner
    ]
  ]

  let generosity-partner [p] of best-neighbor + [q] of best-neighbor
  let generosity-self p + q
  if generosity-partner >= generosity-self + threshold
  [
    ifelse random-float 1 < 0.8
    [
        if p < 0.99 and q < 0.99  [set pcolor pcolor + one-of [12 11 1]] ;; p + 0.1 or q + 0.1 or both + 0.1
        if p < 0.99 and q >= 0.99 [set pcolor pcolor +  11]              ;; if only q is maximal then p + 0.1
        if p >= 0.99 and q < 0.99 [set pcolor pcolor + 1]                ;; if only p is maximal then q + 0.1
    ]
    [set pcolor (random 121) + 10]
  ]
  if generosity-partner <= generosity-self - threshold
  [
    ifelse random-float 1 < 0.8
    [
      if p > 0.01 and q > 0.01 [set pcolor pcolor - one-of [12 11 1]]   ;; p - 0.1 or q - 0.1 or both - 0.1
      if p > 0.01 and q <= 0.01 [set pcolor pcolor - 11]                ;; if only q is minimal then p - 0.1
      if p <= 0.01 and q > 0.01 [set pcolor pcolor - 1]                 ;; if only p is minimal then q - 0.1
    ]
    [set pcolor (random 121) + 10]
  ]

end

to select-opponents
  ask patches
  [
    set opponents [self] of patches in-radius radius
    set opponents remove self opponents
  ]
end

to play-IPD
  ifelse strategies-121 = true
  [
    select-strategy-121
    select-strategy-partner-121
  ]
  [
    select-strategy
    select-strategy-partner
  ]
  calculate-payoff
end

to calculate-payoff
  calc-cx
  calc-cy
  set payoff payoff + (cx * cy * (R- + P- + S- - T-) + (cx * (S- - P-)) + (cy * (T- - P-)) + P-)
end

to calc-cx
  set cx (q + ((p - q) * q-partner)) / (1 - ((p - q) * (p-partner - q-partner)))
end

to calc-cy
  set cy (q-partner + ((p-partner - q-partner) * q)) / (1 - ((p-partner - q-partner) * (p - q)))
end

to calc-av-p
  set average-p sum [p] of patches / count patches
end

to calc-av-q
  set average-q sum [q] of patches / count patches
end

to calc-average-fitness
  set average-fitness (sum [payoff] of patches) / (count patches * (2 * radius * (radius + 1) )) ;; neighborhood is 2r*(r+1)
end

to show-best-strategy
  let most-patches 0
  let code-color 0
  let best-strat 0
  foreach pen-list
  [
    x -> set code-color x
    if count patches with [pcolor = read-from-string code-color] > most-patches
    [
      set most-patches count patches with [pcolor = read-from-string code-color]
      set best-strat read-from-string code-color
    ]
  ]
  if strategies-121 = true [set Best-strategy best-strat - 10]
end

to do-plots
  set-current-plot "Strategies"
  foreach pen-list
  [
    x -> let code-color x
    plot count patches with [pcolor = read-from-string code-color]
    create-temporary-plot-pen  code-color
    set-plot-pen-color read-from-string code-color
  ]
end

to write-file
  file-open "average-fitness.txt"
  file-write average-fitness
  file-close
  file-open "best-strategy.txt"
  file-write Best-strategy
  file-close
  file-open "average-p.txt"
  file-write average-p
  file-close
  file-open "average-q.txt"
  file-write average-q
  file-close
end

;; The PD dilemma occurs when T > R > P > S and 2R > T + S

to default-payoff-matrix
  set R- 3 ;; reward
  set P- 1 ;; punishment
  set S- 0 ;; sucker payoff
  set T- 5 ;; temptation payoff
end

to alternative-1-payoff
  set R- 4
  set P- 1
  set S- 0
  set T- 5
end

to alternative-2-payoff
  set R- 3
  set P- 2
  set S- 1
  set T- 4
end

to select-strategy
  if pcolor = lime [strategy-121]
  if pcolor = red [strategy-1]
  if pcolor = blue [strategy-4]
  if pcolor = green [strategy-8]
  if pcolor = orange [strategy-11]
  if pcolor = pink [strategy-34]
  if pcolor = violet [strategy-37]
  if pcolor = magenta [strategy-41]
  if pcolor = gray [strategy-44]
  if pcolor = yellow [strategy-78]
  if pcolor = turquoise [strategy-81]
  if pcolor = cyan [strategy-85]
  if pcolor = sky [strategy-88]
  if pcolor = black [strategy-111]
  if pcolor = 42 [strategy-114]
  if pcolor = brown [strategy-118]
end

to select-strategy-partner
  if [pcolor] of partner = lime [strategy-partner-121]
  if [pcolor] of partner = red [strategy-partner-1]
  if [pcolor] of partner = blue [strategy-partner-4]
  if [pcolor] of partner = green [strategy-partner-8]
  if [pcolor] of partner = orange [strategy-partner-11]
  if [pcolor] of partner = pink [strategy-partner-34]
  if [pcolor] of partner = violet [strategy-partner-37]
  if [pcolor] of partner = magenta [strategy-partner-41]
  if [pcolor] of partner = gray [strategy-partner-44]
  if [pcolor] of partner = yellow [strategy-partner-78]
  if [pcolor] of partner = turquoise [strategy-partner-81]
  if [pcolor] of partner = cyan [strategy-partner-85]
  if [pcolor] of partner = sky [strategy-partner-88]
  if [pcolor] of partner = black [strategy-partner-111]
  if [pcolor] of partner = 42 [strategy-partner-114]
  if [pcolor] of partner = brown [strategy-partner-118]
end

to select-strategy-121
  if pcolor = 11 [strategy-1]
  if pcolor = 12 [strategy-2]
  if pcolor = 13 [strategy-3]
  if pcolor = 14 [strategy-4]
  if pcolor = 15 [strategy-5]
  if pcolor = 16 [strategy-6]
  if pcolor = 17 [strategy-7]
  if pcolor = 18 [strategy-8]
  if pcolor = 19 [strategy-9]
  if pcolor = 20 [strategy-10]
  if pcolor = 21 [strategy-11]
  if pcolor = 22 [strategy-12]
  if pcolor = 23 [strategy-13]
  if pcolor = 24 [strategy-14]
  if pcolor = 25 [strategy-15]
  if pcolor = 26 [strategy-16]
  if pcolor = 27 [strategy-17]
  if pcolor = 28 [strategy-18]
  if pcolor = 29 [strategy-19]
  if pcolor = 30 [strategy-20]
  if pcolor = 31 [strategy-21]
  if pcolor = 32 [strategy-22]
  if pcolor = 33 [strategy-23]
  if pcolor = 34 [strategy-24]
  if pcolor = 35 [strategy-25]
  if pcolor = 36 [strategy-26]
  if pcolor = 37 [strategy-27]
  if pcolor = 38 [strategy-28]
  if pcolor = 39 [strategy-29]
  if pcolor = 40 [strategy-30]
  if pcolor = 41 [strategy-31]
  if pcolor = 42 [strategy-32]
  if pcolor = 43 [strategy-33]
  if pcolor = 44 [strategy-34]
  if pcolor = 45 [strategy-35]
  if pcolor = 46 [strategy-36]
  if pcolor = 47 [strategy-37]
  if pcolor = 48 [strategy-38]
  if pcolor = 49 [strategy-39]
  if pcolor = 50 [strategy-40]
  if pcolor = 51 [strategy-41]
  if pcolor = 52 [strategy-42]
  if pcolor = 53 [strategy-43]
  if pcolor = 54 [strategy-44]
  if pcolor = 55 [strategy-45]
  if pcolor = 56 [strategy-46]
  if pcolor = 57 [strategy-47]
  if pcolor = 58 [strategy-48]
  if pcolor = 59 [strategy-49]
  if pcolor = 60 [strategy-50]
  if pcolor = 61 [strategy-51]
  if pcolor = 62 [strategy-52]
  if pcolor = 63 [strategy-53]
  if pcolor = 64 [strategy-54]
  if pcolor = 65 [strategy-55]
  if pcolor = 66 [strategy-56]
  if pcolor = 67 [strategy-57]
  if pcolor = 68 [strategy-58]
  if pcolor = 69 [strategy-59]
  if pcolor = 70 [strategy-60]
  if pcolor = 71 [strategy-61]
  if pcolor = 72 [strategy-62]
  if pcolor = 73 [strategy-63]
  if pcolor = 74 [strategy-64]
  if pcolor = 75 [strategy-65]
  if pcolor = 76 [strategy-66]
  if pcolor = 77 [strategy-67]
  if pcolor = 78 [strategy-68]
  if pcolor = 79 [strategy-69]
  if pcolor = 80 [strategy-70]
  if pcolor = 81 [strategy-71]
  if pcolor = 82 [strategy-72]
  if pcolor = 83 [strategy-73]
  if pcolor = 84 [strategy-74]
  if pcolor = 85 [strategy-75]
  if pcolor = 86 [strategy-76]
  if pcolor = 87 [strategy-77]
  if pcolor = 88 [strategy-78]
  if pcolor = 89 [strategy-79]
  if pcolor = 90 [strategy-80]
  if pcolor = 91 [strategy-81]
  if pcolor = 92 [strategy-82]
  if pcolor = 93 [strategy-83]
  if pcolor = 94 [strategy-84]
  if pcolor = 95 [strategy-85]
  if pcolor = 96 [strategy-86]
  if pcolor = 97 [strategy-87]
  if pcolor = 98 [strategy-88]
  if pcolor = 99 [strategy-89]
  if pcolor = 100 [strategy-90]
  if pcolor = 101 [strategy-91]
  if pcolor = 102 [strategy-92]
  if pcolor = 103 [strategy-93]
  if pcolor = 104 [strategy-94]
  if pcolor = 105 [strategy-95]
  if pcolor = 106 [strategy-96]
  if pcolor = 107 [strategy-97]
  if pcolor = 108 [strategy-98]
  if pcolor = 109 [strategy-99]
  if pcolor = 110 [strategy-100]
  if pcolor = 111 [strategy-101]
  if pcolor = 112 [strategy-102]
  if pcolor = 113 [strategy-103]
  if pcolor = 114 [strategy-104]
  if pcolor = 115 [strategy-105]
  if pcolor = 116 [strategy-106]
  if pcolor = 117 [strategy-107]
  if pcolor = 118 [strategy-108]
  if pcolor = 119 [strategy-109]
  if pcolor = 120 [strategy-110]
  if pcolor = 121 [strategy-111]
  if pcolor = 122 [strategy-112]
  if pcolor = 123 [strategy-113]
  if pcolor = 124 [strategy-114]
  if pcolor = 125 [strategy-115]
  if pcolor = 126 [strategy-116]
  if pcolor = 127 [strategy-117]
  if pcolor = 128 [strategy-118]
  if pcolor = 129 [strategy-119]
  if pcolor = 130 [strategy-120]
  if pcolor = 131 [strategy-121]
end

to select-strategy-partner-121
  if [pcolor] of partner = 11 [strategy-partner-1]
  if [pcolor] of partner = 12 [strategy-partner-2]
  if [pcolor] of partner = 13 [strategy-partner-3]
  if [pcolor] of partner = 14 [strategy-partner-4]
  if [pcolor] of partner = 15 [strategy-partner-5]
  if [pcolor] of partner = 16 [strategy-partner-6]
  if [pcolor] of partner = 17 [strategy-partner-7]
  if [pcolor] of partner = 18 [strategy-partner-8]
  if [pcolor] of partner = 19 [strategy-partner-9]
  if [pcolor] of partner = 20 [strategy-partner-10]
  if [pcolor] of partner = 21 [strategy-partner-11]
  if [pcolor] of partner = 22 [strategy-partner-12]
  if [pcolor] of partner = 23 [strategy-partner-13]
  if [pcolor] of partner = 24 [strategy-partner-14]
  if [pcolor] of partner = 25 [strategy-partner-15]
  if [pcolor] of partner = 26 [strategy-partner-16]
  if [pcolor] of partner = 27 [strategy-partner-17]
  if [pcolor] of partner = 28 [strategy-partner-18]
  if [pcolor] of partner = 29 [strategy-partner-19]
  if [pcolor] of partner = 30 [strategy-partner-20]
  if [pcolor] of partner = 31 [strategy-partner-21]
  if [pcolor] of partner = 32 [strategy-partner-22]
  if [pcolor] of partner = 33 [strategy-partner-23]
  if [pcolor] of partner = 34 [strategy-partner-24]
  if [pcolor] of partner = 35 [strategy-partner-25]
  if [pcolor] of partner = 36 [strategy-partner-26]
  if [pcolor] of partner = 37 [strategy-partner-27]
  if [pcolor] of partner = 38 [strategy-partner-28]
  if [pcolor] of partner = 39 [strategy-partner-29]
  if [pcolor] of partner = 40 [strategy-partner-30]
  if [pcolor] of partner = 41 [strategy-partner-31]
  if [pcolor] of partner = 42 [strategy-partner-32]
  if [pcolor] of partner = 43 [strategy-partner-33]
  if [pcolor] of partner = 44 [strategy-partner-34]
  if [pcolor] of partner = 45 [strategy-partner-35]
  if [pcolor] of partner = 46 [strategy-partner-36]
  if [pcolor] of partner = 47 [strategy-partner-37]
  if [pcolor] of partner = 48 [strategy-partner-38]
  if [pcolor] of partner = 49 [strategy-partner-39]
  if [pcolor] of partner = 50 [strategy-partner-40]
  if [pcolor] of partner = 51 [strategy-partner-41]
  if [pcolor] of partner = 52 [strategy-partner-42]
  if [pcolor] of partner = 53 [strategy-partner-43]
  if [pcolor] of partner = 54 [strategy-partner-44]
  if [pcolor] of partner = 55 [strategy-partner-45]
  if [pcolor] of partner = 56 [strategy-partner-46]
  if [pcolor] of partner = 57 [strategy-partner-47]
  if [pcolor] of partner = 58 [strategy-partner-48]
  if [pcolor] of partner = 59 [strategy-partner-49]
  if [pcolor] of partner = 60 [strategy-partner-50]
  if [pcolor] of partner = 61 [strategy-partner-51]
  if [pcolor] of partner = 62 [strategy-partner-52]
  if [pcolor] of partner = 63 [strategy-partner-53]
  if [pcolor] of partner = 64 [strategy-partner-54]
  if [pcolor] of partner = 65 [strategy-partner-55]
  if [pcolor] of partner = 66 [strategy-partner-56]
  if [pcolor] of partner = 67 [strategy-partner-57]
  if [pcolor] of partner = 68 [strategy-partner-58]
  if [pcolor] of partner = 69 [strategy-partner-59]
  if [pcolor] of partner = 70 [strategy-partner-60]
  if [pcolor] of partner = 71 [strategy-partner-61]
  if [pcolor] of partner = 72 [strategy-partner-62]
  if [pcolor] of partner = 73 [strategy-partner-63]
  if [pcolor] of partner = 74 [strategy-partner-64]
  if [pcolor] of partner = 75 [strategy-partner-65]
  if [pcolor] of partner = 76 [strategy-partner-66]
  if [pcolor] of partner = 77 [strategy-partner-67]
  if [pcolor] of partner = 78 [strategy-partner-68]
  if [pcolor] of partner = 79 [strategy-partner-69]
  if [pcolor] of partner = 80 [strategy-partner-70]
  if [pcolor] of partner = 81 [strategy-partner-71]
  if [pcolor] of partner = 82 [strategy-partner-72]
  if [pcolor] of partner = 83 [strategy-partner-73]
  if [pcolor] of partner = 84 [strategy-partner-74]
  if [pcolor] of partner = 85 [strategy-partner-75]
  if [pcolor] of partner = 86 [strategy-partner-76]
  if [pcolor] of partner = 87 [strategy-partner-77]
  if [pcolor] of partner = 88 [strategy-partner-78]
  if [pcolor] of partner = 89 [strategy-partner-79]
  if [pcolor] of partner = 90 [strategy-partner-80]
  if [pcolor] of partner = 91 [strategy-partner-81]
  if [pcolor] of partner = 92 [strategy-partner-82]
  if [pcolor] of partner = 93 [strategy-partner-83]
  if [pcolor] of partner = 94 [strategy-partner-84]
  if [pcolor] of partner = 95 [strategy-partner-85]
  if [pcolor] of partner = 96 [strategy-partner-86]
  if [pcolor] of partner = 97 [strategy-partner-87]
  if [pcolor] of partner = 98 [strategy-partner-88]
  if [pcolor] of partner = 99 [strategy-partner-89]
  if [pcolor] of partner = 100 [strategy-partner-90]
  if [pcolor] of partner = 101 [strategy-partner-91]
  if [pcolor] of partner = 102 [strategy-partner-92]
  if [pcolor] of partner = 103 [strategy-partner-93]
  if [pcolor] of partner = 104 [strategy-partner-94]
  if [pcolor] of partner = 105 [strategy-partner-95]
  if [pcolor] of partner = 106 [strategy-partner-96]
  if [pcolor] of partner = 107 [strategy-partner-97]
  if [pcolor] of partner = 108 [strategy-partner-98]
  if [pcolor] of partner = 109 [strategy-partner-99]
  if [pcolor] of partner = 110 [strategy-partner-100]
  if [pcolor] of partner = 111 [strategy-partner-101]
  if [pcolor] of partner = 112 [strategy-partner-102]
  if [pcolor] of partner = 113 [strategy-partner-103]
  if [pcolor] of partner = 114 [strategy-partner-104]
  if [pcolor] of partner = 115 [strategy-partner-105]
  if [pcolor] of partner = 116 [strategy-partner-106]
  if [pcolor] of partner = 117 [strategy-partner-107]
  if [pcolor] of partner = 118 [strategy-partner-108]
  if [pcolor] of partner = 119 [strategy-partner-109]
  if [pcolor] of partner = 120 [strategy-partner-110]
  if [pcolor] of partner = 121 [strategy-partner-111]
  if [pcolor] of partner = 122 [strategy-partner-112]
  if [pcolor] of partner = 123 [strategy-partner-113]
  if [pcolor] of partner = 124 [strategy-partner-114]
  if [pcolor] of partner = 125 [strategy-partner-115]
  if [pcolor] of partner = 126 [strategy-partner-116]
  if [pcolor] of partner = 127 [strategy-partner-117]
  if [pcolor] of partner = 128 [strategy-partner-118]
  if [pcolor] of partner = 129 [strategy-partner-119]
  if [pcolor] of partner = 130 [strategy-partner-120]
  if [pcolor] of partner = 131 [strategy-partner-121]
end

;; p = probability of cooperative response to cooperation
;; q = probability of cooperative response to defection

to strategy-1
  set p 0.01
  set q 0.01
end

to strategy-partner-1
  set p-partner  0.01
  set q-partner  0.01
end

to strategy-2
  set p 0.01
  set q 0.1
end

to strategy-partner-2
  set p-partner  0.01
  set q-partner  0.1
end


to strategy-3
  set p 0.01
  set q 0.2
end

to strategy-partner-3
  set p-partner  0.01
  set q-partner  0.2
end

to strategy-4
  set p 0.01
  set q 0.3
end

to strategy-partner-4
  set p-partner  0.01
  set q-partner  0.3
end

to strategy-5
  set p 0.01
  set q 0.4
end

to strategy-partner-5
  set p-partner  0.01
  set q-partner  0.4
end

to strategy-6
  set p 0.01
  set q 0.5
end

to strategy-partner-6
  set p-partner  0.01
  set q-partner  0.5
end

to strategy-7
  set p 0.01
  set q 0.6
end

to strategy-partner-7
  set p-partner  0.01
  set q-partner  0.6
end

to strategy-8
  set p 0.01
  set q 0.7
end

to strategy-partner-8
  set p-partner  0.01
  set q-partner  0.7
end

to strategy-9
  set p 0.01
  set q 0.8
end

to strategy-partner-9
  set p-partner  0.01
  set q-partner  0.8
end

to strategy-10
  set p 0.01
  set q 0.9
end

to strategy-partner-10
  set p-partner  0.01
  set q-partner  0.9
end

to strategy-11
  set p 0.01
  set q 0.99
end

to strategy-partner-11
  set p-partner  0.01
  set q-partner  0.99
end

to strategy-12
  set p 0.1
  set q 0.01
end

to strategy-partner-12
  set p-partner  0.1
  set q-partner  0.01
end

to strategy-13
  set p 0.1
  set q 0.1
end

to strategy-partner-13
  set p-partner  0.1
  set q-partner  0.1
end

to strategy-14
  set p 0.1
  set q 0.2
end

to strategy-partner-14
  set p-partner  0.1
  set q-partner  0.2
end

to strategy-15
  set p 0.1
  set q 0.3
end

to strategy-partner-15
  set p-partner  0.1
  set q-partner  0.3
end

to strategy-16
  set p 0.1
  set q 0.4
end

to strategy-partner-16
  set p-partner  0.1
  set q-partner  0.4
end

to strategy-17
  set p 0.1
  set q 0.5
end

to strategy-partner-17
  set p-partner  0.1
  set q-partner  0.5
end

to strategy-18
  set p 0.1
  set q 0.6
end

to strategy-partner-18
  set p-partner  0.1
  set q-partner  0.6
end

to strategy-19
  set p 0.1
  set q 0.7
end

to strategy-partner-19
  set p-partner  0.1
  set q-partner  0.7
end

to strategy-20
  set p 0.1
  set q 0.8
end

to strategy-partner-20
  set p-partner  0.1
  set q-partner  0.8
end

to strategy-21
  set p 0.1
  set q 0.9
end

to strategy-partner-21
  set p-partner  0.1
  set q-partner  0.9
end

to strategy-22
  set p 0.1
  set q 0.99
end

to strategy-partner-22
  set p-partner  0.1
  set q-partner  0.99
end

to strategy-23
  set p 0.2
  set q 0.01
end

to strategy-partner-23
  set p-partner  0.2
  set q-partner  0.01
end

to strategy-24
  set p 0.2
  set q 0.1
end

to strategy-partner-24
  set p-partner  0.2
  set q-partner  0.1
end

to strategy-25
  set p 0.2
  set q 0.2
end

to strategy-partner-25
  set p-partner  0.2
  set q-partner  0.2
end

to strategy-26
  set p 0.2
  set q 0.3
end

to strategy-partner-26
  set p-partner  0.2
  set q-partner  0.3
end

to strategy-27
  set p 0.2
  set q 0.4
end

to strategy-partner-27
  set p-partner  0.2
  set q-partner  0.4
end

to strategy-28
  set p 0.2
  set q 0.5
end

to strategy-partner-28
  set p-partner  0.2
  set q-partner  0.5
end

to strategy-29
  set p 0.2
  set q 0.6
end

to strategy-partner-29
  set p-partner  0.2
  set q-partner  0.6
end

to strategy-30
  set p 0.2
  set q 0.7
end

to strategy-partner-30
  set p-partner  0.2
  set q-partner  0.7
end

to strategy-31
  set p 0.2
  set q 0.8
end

to strategy-partner-31
  set p-partner  0.2
  set q-partner  0.8
end

to strategy-32
  set p 0.2
  set q 0.9
end

to strategy-partner-32
  set p-partner  0.2
  set q-partner  0.9
end

to strategy-33
  set p 0.2
  set q 0.99
end

to strategy-partner-33
  set p-partner  0.2
  set q-partner  0.99
end

to strategy-34
  set p 0.3
  set q 0.01
end

to strategy-partner-34
  set p-partner  0.3
  set q-partner  0.01
end

to strategy-35
  set p 0.3
  set q 0.1
end

to strategy-partner-35
  set p-partner  0.3
  set q-partner  0.1
end

to strategy-36
  set p 0.3
  set q 0.2
end

to strategy-partner-36
  set p-partner  0.3
  set q-partner  0.2
end

to strategy-37
  set p 0.3
  set q 0.3
end

to strategy-partner-37
  set p-partner  0.3
  set q-partner  0.3
end

to strategy-38
  set p 0.3
  set q 0.4
end

to strategy-partner-38
  set p-partner  0.3
  set q-partner  0.4
end

to strategy-39
  set p 0.3
  set q 0.5
end

to strategy-partner-39
  set p-partner  0.3
  set q-partner  0.5
end

to strategy-40
  set p 0.3
  set q 0.6
end

to strategy-partner-40
  set p-partner  0.3
  set q-partner  0.6
end

to strategy-41
  set p 0.3
  set q 0.7
end

to strategy-partner-41
  set p-partner  0.3
  set q-partner  0.7
end

to strategy-42
  set p 0.3
  set q 0.8
end

to strategy-partner-42
  set p-partner  0.3
  set q-partner  0.8
end

to strategy-43
  set p 0.3
  set q 0.9
end

to strategy-partner-43
  set p-partner  0.3
  set q-partner  0.9
end

to strategy-44
  set p 0.3
  set q 0.99
end

to strategy-partner-44
  set p-partner  0.3
  set q-partner  0.99
end

to strategy-45
  set p 0.4
  set q 0.01
end

to strategy-partner-45
  set p-partner  0.4
  set q-partner  0.01
end

to strategy-46
  set p 0.4
  set q 0.1
end

to strategy-partner-46
  set p-partner  0.4
  set q-partner  0.1
end

to strategy-47
  set p 0.4
  set q 0.2
end

to strategy-partner-47
  set p-partner  0.4
  set q-partner  0.2
end

to strategy-48
  set p 0.4
  set q 0.3
end

to strategy-partner-48
  set p-partner  0.4
  set q-partner  0.3
end

to strategy-49
  set p 0.4
  set q 0.4
end

to strategy-partner-49
  set p-partner  0.4
  set q-partner  0.4
end

to strategy-50
  set p 0.4
  set q 0.5
end

to strategy-partner-50
  set p-partner  0.4
  set q-partner  0.5
end

to strategy-51
  set p 0.4
  set q 0.6
end

to strategy-partner-51
  set p-partner  0.4
  set q-partner  0.6
end

to strategy-52
  set p 0.4
  set q 0.7
end

to strategy-partner-52
  set p-partner  0.4
  set q-partner  0.7
end

to strategy-53
  set p 0.4
  set q 0.8
end

to strategy-partner-53
  set p-partner  0.4
  set q-partner  0.8
end

to strategy-54
  set p 0.4
  set q 0.9
end

to strategy-partner-54
  set p-partner  0.4
  set q-partner  0.9
end

to strategy-55
  set p 0.4
  set q 0.99
end

to strategy-partner-55
  set p-partner  0.4
  set q-partner  0.99
end

to strategy-56
  set p 0.5
  set q 0.01
end

to strategy-partner-56
  set p-partner  0.5
  set q-partner  0.01
end

to strategy-57
  set p 0.5
  set q 0.1
end

to strategy-partner-57
  set p-partner  0.5
  set q-partner  0.1
end

to strategy-58
  set p 0.5
  set q 0.2
end

to strategy-partner-58
  set p-partner  0.5
  set q-partner  0.2
end

to strategy-59
  set p 0.5
  set q 0.3
end

to strategy-partner-59
  set p-partner  0.5
  set q-partner  0.3
end

to strategy-60
  set p 0.5
  set q 0.4
end

to strategy-partner-60
  set p-partner  0.5
  set q-partner  0.4
end

to strategy-61
  set p 0.5
  set q 0.5
end

to strategy-partner-61
  set p-partner  0.5
  set q-partner  0.5
end

to strategy-62
  set p 0.5
  set q 0.6
end

to strategy-partner-62
  set p-partner  0.5
  set q-partner  0.6
end

to strategy-63
  set p 0.5
  set q 0.7
end

to strategy-partner-63
  set p-partner  0.5
  set q-partner  0.7
end

to strategy-64
  set p 0.5
  set q 0.8
end

to strategy-partner-64
  set p-partner  0.5
  set q-partner  0.8
end

to strategy-65
  set p 0.5
  set q 0.9
end

to strategy-partner-65
  set p-partner  0.5
  set q-partner  0.9
end

to strategy-66
  set p 0.5
  set q 0.99
end

to strategy-partner-66
  set p-partner 0.5
  set q-partner 0.99
end

to strategy-67
  set p 0.6
  set q 0.01
end

to strategy-partner-67
  set p-partner  0.6
  set q-partner  0.01
end

to strategy-68
  set p 0.6
  set q 0.1
end

to strategy-partner-68
  set p-partner  0.6
  set q-partner  0.1
end

to strategy-69
  set p 0.6
  set q 0.2
end

to strategy-partner-69
  set p-partner  0.6
  set q-partner  0.2
end

to strategy-70
  set p 0.6
  set q 0.3
end

to strategy-partner-70
  set p-partner  0.6
  set q-partner  0.3
end

to strategy-71
  set p 0.6
  set q 0.4
end

to strategy-partner-71
  set p-partner  0.6
  set q-partner  0.4
end

to strategy-72
  set p 0.6
  set q 0.5
end

to strategy-partner-72
  set p-partner  0.6
  set q-partner  0.5
end

to strategy-73
  set p 0.6
  set q 0.6
end

to strategy-partner-73
  set p-partner  0.6
  set q-partner  0.6
end

to strategy-74
  set p 0.6
  set q 0.7
end

to strategy-partner-74
  set p-partner  0.6
  set q-partner  0.7
end

to strategy-75
  set p 0.6
  set q 0.8
end

to strategy-partner-75
  set p-partner  0.6
  set q-partner  0.8
end

to strategy-76
  set p 0.6
  set q 0.9
end

to strategy-partner-76
  set p-partner  0.6
  set q-partner  0.9
end

to strategy-77
  set p 0.6
  set q 0.99
end

to strategy-partner-77
  set p-partner  0.6
  set q-partner  0.99
end

to strategy-78
  set p 0.7
  set q 0.01
end

to strategy-partner-78
  set p-partner  0.7
  set q-partner  0.01
end

to strategy-79
  set p 0.7
  set q 0.1
end

to strategy-partner-79
  set p-partner  0.7
  set q-partner  0.1
end

to strategy-80
  set p 0.7
  set q 0.2
end

to strategy-partner-80
  set p-partner  0.7
  set q-partner  0.2
end

to strategy-81
  set p 0.7
  set q 0.3
end

to strategy-partner-81
  set p-partner  0.7
  set q-partner  0.3
end

to strategy-82
  set p 0.7
  set q 0.4
end

to strategy-partner-82
  set p-partner  0.7
  set q-partner  0.4
end

to strategy-83
  set p 0.7
  set q 0.5
end

to strategy-partner-83
  set p-partner  0.7
  set q-partner  0.5
end

to strategy-84
  set p 0.7
  set q 0.6
end

to strategy-partner-84
  set p-partner  0.7
  set q-partner  0.6
end

to strategy-85
  set p 0.7
  set q 0.7
end

to strategy-partner-85
  set p-partner  0.7
  set q-partner  0.7
end

to strategy-86
  set p 0.7
  set q 0.8
end

to strategy-partner-86
  set p-partner  0.7
  set q-partner  0.8
end

to strategy-87
  set p 0.7
  set q 0.9
end

to strategy-partner-87
  set p-partner  0.7
  set q-partner  0.9
end

to strategy-88
  set p 0.7
  set q 0.99
end

to strategy-partner-88
  set p-partner  0.7
  set q-partner  0.99
end

to strategy-89
  set p 0.8
  set q 0.01
end

to strategy-partner-89
  set p-partner  0.8
  set q-partner 0.01
end

to strategy-90
  set p 0.8
  set q 0.1
end

to strategy-partner-90
  set p-partner  0.8
  set q-partner  0.1
end

to strategy-91
  set p 0.8
  set q 0.2
end

to strategy-partner-91
  set p-partner  0.8
  set q-partner  0.2
end

to strategy-92
  set p 0.8
  set q 0.3
end

to strategy-partner-92
  set p-partner  0.8
  set q-partner  0.3
end

to strategy-93
  set p 0.8
  set q 0.4
end

to strategy-partner-93
  set p-partner  0.8
  set q-partner  0.4
end

to strategy-94
  set p 0.8
  set q 0.5
end

to strategy-partner-94
  set p-partner  0.8
  set q-partner  0.5
end

to strategy-95
  set p 0.8
  set q 0.6
end

to strategy-partner-95
  set p-partner  0.8
  set q-partner  0.6
end

to strategy-96
  set p 0.8
  set q 0.7
end

to strategy-partner-96
  set p-partner  0.8
  set q-partner  0.7
end

to strategy-97
  set p 0.8
  set q 0.8
end

to strategy-partner-97
  set p-partner  0.8
  set q-partner  0.8
end

to strategy-98
  set p 0.8
  set q 0.9
end

to strategy-partner-98
  set p-partner  0.8
  set q-partner  0.9
end

to strategy-99
  set p 0.8
  set q 0.99
end

to strategy-partner-99
  set p-partner  0.8
  set q-partner  0.99
end

to strategy-100
  set p 0.9
  set q 0.01
end

to strategy-partner-100
  set p-partner  0.9
  set q-partner  0.01
end

to strategy-101
  set p 0.9
  set q 0.1
end

to strategy-partner-101
  set p-partner  0.9
  set q-partner  0.1
end

to strategy-102
  set p 0.9
  set q 0.2
end

to strategy-partner-102
  set p-partner  0.9
  set q-partner  0.2
end

to strategy-103
  set p 0.9
  set q 0.3
end

to strategy-partner-103
  set p-partner  0.9
  set q-partner  0.3
end

to strategy-104
  set p 0.9
  set q 0.4
end

to strategy-partner-104
  set p-partner  0.9
  set q-partner  0.4
end

to strategy-105
  set p 0.9
  set q 0.5
end

to strategy-partner-105
  set p-partner  0.9
  set q-partner  0.5
end

to strategy-106
  set p 0.9
  set q 0.6
end

to strategy-partner-106
  set p-partner  0.9
  set q-partner  0.6
end

to strategy-107
  set p 0.9
  set q 0.7
end

to strategy-partner-107
  set p-partner  0.9
  set q-partner  0.7
end

to strategy-108
  set p 0.9
  set q 0.8
end

to strategy-partner-108
  set p-partner  0.9
  set q-partner  0.8
end

to strategy-109
  set p 0.9
  set q 0.9
end

to strategy-partner-109
  set p-partner  0.9
  set q-partner  0.9
end

to strategy-110
  set p 0.9
  set q 0.99
end

to strategy-partner-110
  set p-partner  0.9
  set q-partner  0.99
end

to strategy-111
  set p 0.99
  set q 0.01
end

to strategy-partner-111
  set p-partner  0.99
  set q-partner  0.01
end

to strategy-112
  set p 0.99
  set q 0.1
end

to strategy-partner-112
  set p-partner  0.99
  set q-partner  0.1
end

to strategy-113
  set p 0.99
  set q 0.2
end

to strategy-partner-113
  set p-partner  0.99
  set q-partner  0.2
end

to strategy-114
  set p 0.99
  set q 0.3
end

to strategy-partner-114
  set p-partner  0.99
  set q-partner  0.3
end

to strategy-115
  set p 0.99
  set q 0.4
end

to strategy-partner-115
  set p-partner  0.99
  set q-partner  0.4
end

to strategy-116
  set p 0.99
  set q 0.5
end

to strategy-partner-116
  set p-partner  0.99
  set q-partner  0.5
end

to strategy-117
  set p 0.99
  set q 0.6
end

to strategy-partner-117
  set p-partner  0.99
  set q-partner  0.6
end

to strategy-118
  set p 0.99
  set q 0.7
end

to strategy-partner-118
  set p-partner  0.99
  set q-partner  0.7
end

to strategy-119
  set p 0.99
  set q 0.8
end

to strategy-partner-119
  set p-partner  0.99
  set q-partner  0.8
end

to strategy-120
  set p 0.99
  set q 0.9
end

to strategy-partner-120
  set p-partner  0.99
  set q-partner  0.9
end

to strategy-121
  set p 0.99
  set q 0.99
end

to strategy-partner-121
  set p-partner  0.99
  set q-partner  0.99
end







@#$#@#$#@
GRAPHICS-WINDOW
185
25
598
439
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-40
40
-40
40
0
0
1
ticks
30.0

BUTTON
10
25
90
58
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
90
25
180
58
go once
go
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
10
60
180
93
go forever
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
10
95
200
128
radius
radius
1
6
2.0
1
1
NIL
HORIZONTAL

PLOT
605
15
885
190
Average Fitness
Time steps
Average fitness
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Fitness" 1.0 0 -5298144 true "" "plot average-fitness"

PLOT
1135
105
1570
385
Strategy count
NIL
NIL
0.0
10.0
350.0
10.0
true
true
"" ""
PENS
"(0.01, 0.01)" 1.0 0 -2674135 true "" "if small-plot = true [plot count patches with [pcolor = red]]"
"(0.01, 0.3)" 1.0 0 -13345367 true "" "if small-plot = true [plot count patches with [pcolor = blue]]"
"(0.01, 0.7)" 1.0 0 -10899396 true "" "if small-plot = true [plot count patches with [pcolor = green]]"
"(0.01, 0.99)" 1.0 0 -955883 true "" "if small-plot = true [plot count patches with [pcolor = orange]]"
"(0.3, 0.01)" 1.0 0 -2064490 true "" "if small-plot = true [plot count patches with [pcolor = pink]]"
"(0.3, 0.3)" 1.0 0 -8630108 true "" "if small-plot = true [plot count patches with [pcolor = violet]]"
"(0.3, 0.7)" 1.0 0 -5825686 true "" "if small-plot = true [plot count patches with [pcolor = magenta]]"
"(0.3, 0.99)" 1.0 0 -7500403 true "" "if small-plot = true [plot count patches with [pcolor = gray]]"
"(0.7, 0.01)" 1.0 0 -1184463 true "" "if small-plot = true [plot count patches with [pcolor = yellow]]"
"(0.7, 0.3)" 1.0 0 -14835848 true "" "if small-plot = true [plot count patches with [pcolor = turquoise]]"
"(0.7, 0.7)" 1.0 0 -11221820 true "" "if small-plot = true [plot count patches with [pcolor = cyan]]"
"(0.7, 0.99)" 1.0 0 -13791810 true "" "if small-plot = true [plot count patches with [pcolor = sky]]"
"(0.99, 0.01)" 1.0 0 -16777216 true "" "if small-plot = true [plot count patches with [pcolor = 0]]"
"(0.99, 0.3)" 1.0 0 -10263788 true "" "if small-plot = true [plot count patches with [pcolor = 42]]"
"(0.99, 0.7)" 1.0 0 -6459832 true "" "if small-plot = true [plot count patches with [pcolor = brown]]"
"(0.99, 0.99)" 1.0 0 -13840069 true "" "if small-plot = true [plot count patches with [pcolor = lime]]"

CHOOSER
10
130
183
175
update-strategy
update-strategy
"Grim" "Grim-variation" "Wang" "New1" "New2" "Per patch"
1

SLIDER
10
215
182
248
S-
S-
0
5
0.0
1
1
NIL
HORIZONTAL

SLIDER
10
250
182
283
R-
R-
0
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
10
285
182
318
T-
T-
0
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
10
320
182
353
P-
P-
0
5
1.0
1
1
NIL
HORIZONTAL

BUTTON
10
180
180
213
NIL
default-payoff-matrix
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
355
152
388
NIL
alternative-1-payoff
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
390
152
423
NIL
alternative-2-payoff
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
890
65
1040
98
strategies-121
strategies-121
0
1
-1000

PLOT
605
195
1060
435
Strategies
Time
Nr of patches
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

SWITCH
1045
30
1195
63
big-plot
big-plot
1
1
-1000

MONITOR
890
105
962
150
NIL
Average-p
3
1
11

MONITOR
965
105
1037
150
NIL
Average-q
3
1
11

MONITOR
1040
105
1127
150
NIL
Best-strategy
1
1
11

SWITCH
1045
65
1187
98
show-best-strat
show-best-strat
1
1
-1000

SWITCH
890
30
1040
63
small-plot
small-plot
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
