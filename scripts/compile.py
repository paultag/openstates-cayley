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
        x = x.replace('\n', '\\n') if '\n' in x else x
        x = x.replace('\r', '\\r') if '\r' in x else x

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

    /bill/subject

    /bill/id
    /bill/state
    /bill/title
    /bill/session
    """
    id_ = Id(bill['_id'])
    bill_id = bill['bill_id']
    state = Id(bill['state'])
    session = bill['session']

    yield Tripple(id_, "/bill/id", bill_id)
    yield Tripple(id_, "/bill/title", bill['title'])
    yield Tripple(id_, "/bill/state", state)
    yield Tripple(id_, "/bill/session", session)

    for subject in bill.get("subjects", []):  # + bill.get("scraped_subjects", []):
        slug = subject.lower().replace(" ", "-")
        subject = "/subject/{}".format(slug)
        yield Tripple(id_, "/bill/subject", Id(subject))


    for sponsor in bill['sponsors']:
        lid = sponsor['leg_id']
        if lid is not None:
            lid = Id(lid)
            # yield Tripple(id_, "/bill/sponsor", lid)
            yield Tripple(id_, "/bill/sponsor/{}".format(sponsor['type']), lid)


def graph_person(person):
    """
    /legislator/name
    /legislator/party
    /legislator/state
    /committee/member
    """
    lid = Id(person['_id'])
    name = person['full_name']
    state = person['state']

    yield Tripple(lid, "/legislator/name", name)
    yield Tripple(lid, "/legislator/state", state)
    for role in person.get("roles", []):
        cid = role.get("committee_id", None)
        if cid is None:
            continue
        yield Tripple(lid, "/committee/member", Id(cid))

    party = person.get("party", None)
    if party:
        slug = party.lower().replace(" ", "-")
        party_id = "/political/party/{}".format(slug)
        yield Tripple(lid, "/legislator/party", Id(party_id))


def graph_vote(vote):
    """
    /vote/passed
    /vote/state
    /legislator/vote/yes
    /legislator/vote/no
    /legislator/vote/other
    /bill/vote
    """
    vid = Id(vote['_id'])
    bid = Id(vote['bill_id'])
    state = Id(vote['state'])

    yield Tripple(vid, "/vote/state", state)
    yield Tripple(vid, "/vote/passed", "true" if vote['passed'] else "false")
    yield Tripple(bid, "/bill/vote", vid)

    for vk, tk in [
        ("yes_votes", "yes"),
        ("no_votes", "no"),
        ("other_votes", "other"),
    ]:
        # yield Tripple(Id(lid), "/legislator/vote", vid)
        for entry in vote[vk]:
            lid = entry.get("leg_id")
            if lid is None:
                continue
            yield Tripple(Id(lid), "/legislator/vote/{}".format(tk), vid)


def graph(node):
    yield from {
        "bill": graph_bill,
        "person": graph_person,
        "vote": graph_vote,
    }[node['_type']](node)


def output(it):
    seen = set()
    for el in it:
        for tripple in el:
            el = tripple.to_cayley()
            if el in seen:
                sys.stderr.write("Skipping tripple: {}\n".format(el))
                sys.stderr.flush()
                continue
            seen.add(el)
            print(el)



def main(state=None):
    db = connection.fiftystates

    query = {}
    if state:
        query['state'] = state

    for iterable in [
        db.bills,
        db.legislators,
        db.votes,
    ]:
        output(map(graph, iterable.find(query)))


if __name__ == "__main__":
    main(*sys.argv[1:])
