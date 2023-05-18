from typing import List, Optional, Tuple
from dataclasses import dataclass
from pathlib import Path

from rich import print as P
from PIL import Image
from distinctipy import distinctipy
from term_image.image import AutoImage as a


def lines_to_tree(lines) -> "Tree":
    tab_roots = {}
    for index, line in enumerate(lines):
        if len(line.strip()) == 0:
            continue
        level = len(line.split("\t")) - 1
        text = line.strip()
        node = Tree(index, level, text)
        tab_roots[level] = node
        if level - 1 in tab_roots:
            tab_roots[level - 1].c.append(node)
    return tab_roots[0]


@dataclass
class IYL:
    low_y: float
    index: int
    nxt: Optional["IYL"] = None


def update_IYL(min_y: float, i: int, ih: Optional[IYL]):
    # Remove siblings that are hidden by the new subtree
    while ih != None:
        if min_y >= ih.low_y:
            ih = ih.nxt
        else:
            break
    # Prepend the new subtree
    return IYL(min_y, i, ih)


@dataclass
class Tree:
    index: int = -1  # check for null Tree
    level: int = -1  # depth
    text: str = ""  # content

    # Threads
    tl: Optional["Tree"] = None
    tr: Optional["Tree"] = None

    # Extremes
    el: Optional["Tree"] = None
    er: Optional["Tree"] = None

    # move subtree in O(1)
    prelim: float = 0
    mod: float = 0

    # add spacing in O(1)
    shift: float = 0
    change: float = 0

    # mod shift of extremes
    msel: float = 0
    mser: float = 0

    def __post_init__(self):
        self.c: List["Tree"] = []  # children
        self.h, self.w = 1, len(self.text)
        self.y = self.level  # For now, layered tree
        self.x: float = 0  # What we need to calculate

    @property
    def cs(self):
        return len(self.c)


def set_extremes(t: Tree) -> None:
    if t.cs == 0:
        t.el = t
        t.er = t
        t.msel = t.mser = 0
    else:
        t.el = t.c[0].el
        t.msel = t.c[0].msel
        t.er = t.c[t.cs - 1].er
        t.mser = t.c[t.cs - 1].mser


def bottom(t: Tree) -> float:
    return t.y + t.h


def next_left_contour(t: Tree):
    if t.cs == 0:
        return t.tl
    else:
        return t.c[0]


def set_left_thread(t: Tree, i: int, cl: Tree, modsumcl: float) -> None:
    li = t.c[0].el
    assert isinstance(li, Tree), f"⌾ {t.c[0].text}"

    li.tl = cl
    # Change mod so that the sum of modifier after following thread is correct
    diff = (modsumcl - cl.mod) - t.c[0].msel
    li.mod += diff
    # Change preliminary x coordinate so that the node does not move
    li.prelim -= diff
    # Update extreme node and its sum of modifiers
    t.c[0].el = t.c[i].el
    t.c[0].msel = t.c[i].msel


def set_right_thread(t: Tree, i: int, sr: Tree, modsumsr: float):
    ri = t.c[i].er
    assert isinstance(ri, Tree), f"⌾ {t.c[i].text}"

    ri.tr = sr
    diff = (modsumsr - sr.mod) - t.c[i].mser
    ri.mod += diff
    ri.prelim -= diff
    t.c[i].er = t.c[i - 1].er
    t.c[i].mser = t.c[i - 1].mser


def next_right_contour(t: Tree):
    if t.cs == 0:
        return t.tr
    else:
        return t.c[t.cs - 1]


def position_root(t: Tree) -> None:
    # Position root between children, taking into account their mod
    t.prelim = (
        t.c[0].prelim
        + t.c[0].mod
        + t.c[t.cs - 1].mod
        + t.c[t.cs - 1].prelim
        + t.c[t.cs - 1].w
    ) / 2 - t.w / 2


def distribute_extra(t: Tree, i: int, si: int, dist: float) -> None:
    # Are there intermediate children?
    if si != i - 1:
        nr = i - si
        t.c[si + 1].shift += dist / nr
        t.c[i].shift -= dist / nr
        t.c[i].change -= dist - dist / nr


def move_subtree(t: Tree, i: int, si: int, dist: float) -> None:
    print(f"Moving: {t.c[i].text:5s} : {i}, {si}, {dist}")
    # Move subtree by changing mod
    t.c[i].mod += dist
    t.c[i].msel += dist
    t.c[i].mser += dist
    # TODO: i = si occurs here
    if i != si:
        distribute_extra(t, i, si, dist)
    # else:
    #     print(f"i == si : {i} == {si} : {t}")
    #     P(t)


def seperate(t: Tree, i: int, ih: Optional[IYL]):
    # Right contour node of left siblings and its sum of modfiers
    sr = t.c[i - 1]
    mssr = sr.mod

    # Left contour node of current subtree and its sum of modfiers
    cl = t.c[i]
    mscl = cl.mod

    while (sr != None) & (cl != None):
        assert isinstance(ih, IYL), f"⌾ ih {ih}"
        assert isinstance(sr, Tree), f"⌾ sr {sr}"
        assert isinstance(cl, Tree), f"⌾ cl {cl}"

        if bottom(sr) > ih.low_y:
            ih = ih.nxt

        # How far to the left of the right side of sr is the left side of cl?
        dist = (mssr + sr.prelim + sr.w) - (mscl + cl.prelim)
        if dist > 0:
            mscl += dist
            assert isinstance(ih, IYL), f"⌾ ih {ih}"
            move_subtree(t, i, ih.index, dist)
        sy = bottom(sr)
        cy = bottom(cl)

        # Advance highest node(s) and sum(s) of modifiers
        if sy <= cy:
            sr = next_right_contour(sr)
            if sr != None:
                mssr += sr.mod

        if sy >= cy:
            cl = next_left_contour(cl)
            if cl != None:
                mscl += cl.mod

        # Set threads and update extreme nodes
        # In the first case, the current subtree must be taller than the left siblings
        if isinstance(cl, Tree) & (sr == None):
            set_left_thread(t, i, cl, mscl)  # type: ignore
        elif isinstance(sr, Tree) & (cl == None):
            set_right_thread(t, i, sr, mssr)  # type: ignore


def first_walk(t: Tree) -> None:
    if t.cs == 0:
        set_extremes(t)
        return

    # Walk first child to set el, etc
    first_walk(t.c[0])

    # Create siblings in contour minimal vertical coordinate and index list
    assert isinstance(t.c[0].el, Tree), f"⌾ {t.c[0].text}"
    ih = update_IYL(bottom(t.c[0].el), 0, None)

    for i, child in enumerate(t.c[1:]):
        first_walk(child)
        # Store lowest vertical coordinate while extreme nodes still point in current subtree
        assert isinstance(child.er, Tree), f"⌾ {child.text}"
        min_y = bottom(child.er)
        seperate(t, i, ih)
        ih = update_IYL(min_y, i, ih)

    position_root(t)
    set_extremes(t)


def add_child_spacing(t: Tree):
    d = 0
    modsumdelta = 0
    for child in t.c:
        d += child.shift
        modsumdelta += d + child.change
        child.mod += modsumdelta


def second_walk(t: Tree, modsum: float):
    modsum += t.mod
    # Set absolute (non-relative) horizontal coordinate
    t.x = t.prelim + modsum
    add_child_spacing(t)
    for child in t.c:
        second_walk(child, modsum)


def layout(t: Tree):
    for child in t.c:
        layout(child)
    first_walk(t)
    second_walk(t, 0)


def get_max_size(t: Tree, size: Tuple[int, int]):
    size = max(size[0], int(t.x + t.w)), max(size[1], int(t.y + t.h))
    for child in t.c:
        size = get_max_size(child, size)
    return size


def render_tree(t: Tree, image: Image.Image):
    x, y, h, w = int(t.x), int(t.y), t.h, t.w
    x, y, h, w = [v for v in [x, y, h, w]]
    image.paste(
        Image.new("RGB", (w, h), color=COLORS[t.index]),
        (x, y),
    )
    # print(t.text, t.index, x, y, h, w)
    for child in t.c:
        render_tree(child, image)
    return image


def show(t: Tree) -> Image.Image:
    image = Image.new("RGB", get_max_size(t, (0, 0)), color="black")
    render = render_tree(t, image)
    print(a(render))
    return render


if __name__ == "__main__":
    # Create the tree
    lines = Path("./data/simple.hmm").read_text().split("\n")
    COLORS = {
        i: tuple(int(x * 255) for x in c)
        for i, c in enumerate(distinctipy.get_colors(len(lines)))
    }

    tree = lines_to_tree(lines)
    show(tree)

    layout(tree)
    show(tree)
