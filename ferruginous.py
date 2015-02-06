from pymongo import Connection
import sys

connection = Connection("localhost", 27017)

class Id:
    def __init__(self, name):
        self.name = name

    def __str__(self):
        return "<{}>".format(self.name)


class Tripple:
    def __init__(self, in_, relation, out):
        self.in_ = in_

        if not isinstance(relation, Id):
            relation = Id(relation)

        self.relation = relation
        self.out = out

    def _format(self, node):
        if isinstance(node, Id):
            return str(node)

        x = str(node)
        x = x.replace("\\", "\\\\") if "\\" in x else x
        x = x.replace('"', '\\"') if '"' in x else x

        return '"{}"'.format(x)

    def to_cayley(self):
        return "{} {} {} .".format(
            self._format(self.in_),
            self._format(self.relation),
            self._format(self.out),
        )


def graph_bill(bill):
    """
    /bill/sponsor/primary
    /bill/sponsor/secondary
    /bill/sponsor

    /bill/subject

    /bill/id
    /bill/state
    /bill/session
    """
    id_ = Id(bill['_id'])
    bill_id = bill['bill_id']
    state = Id(bill['state'])
    session = bill['session']

    yield Tripple(id_, "/bill/id", bill_id)
    yield Tripple(id_, "/bill/state", state)
    yield Tripple(id_, "/bill/session", session)

    for subject in bill.get("subjects", []) + bill.get("scraped_subjects", []):
        yield Tripple(id_, "/bill/subject", subject)


    for sponsor in bill['sponsors']:
        lid = sponsor['leg_id']
        if lid is not None:
            lid = Id(lid)
            yield Tripple(id_, "/bill/sponsor", lid)
            yield Tripple(id_, "/bill/sponsor/{}".format(sponsor['type']), lid)



def graph(node):
    yield from {
        "bill": graph_bill,
    }[node['_type']](node)


def output(it):
    for el in it:
        for tripple in el:
            print(tripple.to_cayley())



def main(state=None):
    db = connection.fiftystates

    query = {}
    if state:
        query['state'] = state

    for iterable in [
        db.bills,
        # db.legislators,
        # db.votes,
    ]:
        output(map(graph, iterable.find(query)))


if __name__ == "__main__":
    main(*sys.argv[1:])
