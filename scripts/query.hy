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


(defn fetcher [root]
  (fn [el tag path] (-> el (.Out path) (.Tag tag) (.Back root))))

;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;


(cayley/connect "http://localhost:8888"
  (let [[leg "CAL000141"]
        [Fetch (fetcher "leg_id")]
        [cosponsors (query/g->
          (.V leg)
            (.In ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
            (.Out ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
            (.Tag "leg_id")

            (Fetch "name" "/legislator/name")
            (Fetch "state" "/legislator/state")

            (.GetLimit 20))]
        [-- (print (get cosponsors 2))]
        [rank (Counter (map (fn [x] (get x "id")) cosponsors))]]

  (print (.format "Most often sponsors with {}" leg))
  (for [(, leg rank) (.most-common rank 20)]
    (print " " leg rank))))
