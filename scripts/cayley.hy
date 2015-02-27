
(defmacro/g! cayley/connect [server &rest body]
  `(do (import [pyley [CayleyClient GraphObject]])
       (let [[-cayley-server (CayleyClient ~server)]] ~@body)))


(defmacro/g! g-> [&rest things]
  `(let [[g (GraphObject)]
         [~g!query (-> g ~@things)]]
    ~g!query))


(defmacro/g! query [q]
  `(. (.Send -cayley-server ~q) result ["result"]))


(defmacro/g! query/g-> [&rest body]
  `(query (g-> ~@body)))


(defn fetcher [root]
  (fn [el tag path] (-> el (.Out path) (.Tag tag) (.Back root))))
