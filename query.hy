(import [pyley [CayleyClient GraphObject]]
        [collections [Counter]])


(defmacro/g! cayley [&rest body]
  "Get a Cayley Client session open"

  `(let [[cayley-client* (CayleyClient "http://localhost:8888")]]
    ~@body))


(defmacro/g! query [&rest path]
  "Query the server"

  `(let [[~g!g (GraphObject)]
         [~g!query (-> ~g!g ~@path)]
         [~g!response (.Send cayley-client* ~g!query)]]
    (get (. ~g!response result) "result")))



(cayley
  (let [[edges (query (.V "CAL000141")
                      (.In "/bill/sponsor/cosponsor")
                      (.Out "/bill/sponsor/cosponsor")
                      (.All))]
        [rank (Counter (map (fn [x] (get x "id")) edges))]]
    (print rank)))
