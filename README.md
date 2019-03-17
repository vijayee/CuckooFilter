# CuckooFilter
This is a ponylang library for CuckooFilter set memberships

https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf

## Abstract
In many networking systems, Bloom filters are used for highspeed
set membership tests. They permit a small fraction
of false positive answers with very good space efficiency.
However, they do not permit deletion of items from the set,
and previous attempts to extend “standard” Bloom filters to
support deletion all degrade either space or performance.
We propose a new data structure called the cuckoo filter
that can replace Bloom filters for approximate set membership
tests. Cuckoo filters support adding and removing items
dynamically while achieving even higher performance than
Bloom filters. For applications that store many items and
target moderately low false positive rates, cuckoo filters have
lower space overhead than space-optimized Bloom filters.
Our experimental results also show that cuckoo filters outperform
previous data structures that extend Bloom filters to
support deletions substantially in both time and space.

* Install [pony-stable](https://github.com/ponylang/pony-stable)
* Update your `bundle.json`

```json
{
  "type": "github",
  "repo": "vijayee/CuckooFilter"
}
```

* `stable fetch` to fetch your dependencies
* `use "CuckooFilter"` to include this package
* `stable env ponyc` to compile your application
