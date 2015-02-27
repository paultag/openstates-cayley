(import [pyley [CayleyClient GraphObject]]
        [collections [Counter]])


(defmacro/g! cayley/connect [server &rest body]
  `(let [[-cayley-server (CayleyClient ~server)]] ~@body))


(defmacro/g! g-> [&rest things]
  `(let [[g (GraphObject)]
         [~g!query (-> g ~@things)]]
    ~g!query))


(defmacro/g! query/g-> [&rest body]
  `(. (.Send -cayley-server (g-> ~@body)) result ["result"]))


;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;


(cayley/connect "http://localhost:8888"
  (let [[leg "CAL000141"]
        [cosponsors (query/g->
          (.V leg)
            (.In ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
            (.Out ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
            (.All))]
        [rank (Counter (map (fn [x] (get x "id")) cosponsors))]]

  (print (.format "Most often sponsors with {}" leg))
  (for [(, leg rank) (.most-common rank 20)]
    (print " " leg rank))))
