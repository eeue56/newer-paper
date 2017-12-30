from typing import List, Dict, Any, Tuple

class Zipper(object):
    def __init__(self, current: Any, rest: List[Any]) -> None:
        self._current = current
        self._before : List[Any] = []
        self._after = rest 

    @property
    def current(self) -> Any:
        return self._current

    @property
    def after(self) -> List[Any]:
        return self._after

    @property 
    def before(self) -> List[Any]:
        return self._before

    def first(self) -> None:
        if len(self._before) == 0:
            return

        old_current = self._current
        self._current = self._before[0]
        self._after = self._before[1:] + [ old_current ] +  self._after
        self._before = []

    def last(self) -> None:
        if len(self._after) == 0:
            return 

        old_current = self._current
        self._current = self._after[-1]
        self._before = self._before + [ old_current ] + self._after[:-1]
        self._after = []

    def next(self) -> None:
        if len(self._after) == 0:
            return 

        old_current = self._current
        self._current = self._after[0]
        self._before = self._before + [ old_current ] + self._after[1:]
        self._after = []

    @property
    def size(self) -> int:
        return len(self._before) + len(self._after) + 1

    @property
    def current_index(self) -> int:
        return len(self._before)