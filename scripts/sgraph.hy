(import [collections [Counter]]
        [pyley [CayleyClient GraphObject]])


(defn ? [server body]
  (. (.Send server body) result ["result"]))


(defmacro --> [&rest args] `(.Out ~@args))
(defmacro <--> [&rest args] `(.Both ~@args))
(defmacro <-- [&rest args] `(.In ~@args))
(defmacro g-> [&rest args] `(-> g ~@args))


(defn ->t<- [el tag name back]
  (-> el
    (--> tag)
    (.Tag name)
    (.Back back)))


(defmacro defn/g [name signature &rest body]
  `(defn ~name [~@signature]
     (import [pyley [GraphObject]])
     (setv g (GraphObject))  ; let is overkill here
      ~@body))


(defn/g get-legislators [server]
  (? server
    (g-> (.V)
      (.Tag "leg_id")
      ; get name and state
      (->t<- "/legislator/name" "name" "leg_id")
      (->t<- "/legislator/state" "state" "leg_id")
      (.All))))


(defn generate-vector-count [data]
  (if (nil? data)
    []
    (let [[stream (map (fn [x] (get x "id")) data)]
          [count (Counter stream)]]
      (.most-common count 20))))


(defn/g sponsorship-vector [server leg]
  " Generate the vector of sponsorships "
  (let [[leg-id (get leg "id")]
        [data (? server
                (g-> (.V leg-id)
                  (<-- ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
                  (--> ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
                  (.All)))]]
    (generate-vector-count data)))


(defn save-data [leg vector]
  (print leg vector))


(defn generate-sponsorship-vector [server leg]
  (save-data leg (sponsorship-vector server leg)))


(defn generate-sponsorship-vectors [server legs]
  (for [leg legs] (generate-sponsorship-vector server leg)))


(let [[client (CayleyClient "http://localhost:8888")]]
  (generate-sponsorship-vectors client (get-legislators client)))
