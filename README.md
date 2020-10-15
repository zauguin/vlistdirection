# `vlistdirection`
LuaTeX's directional model assigns a single box direction to every vbox.
In bidirectional documents, this can lead to issues where the current
text direction does not correspond to the direction of the enclosing box.
This is a particular problem for the main vertical list whose direction
depends on the position where the output routine is invoked.

To avoid this, we add a new direction register `\vlistdirection` which emulates a change in
directiion in the middle of a vertical list.

The only supported values are `0` (for l2r) and `1` (for r2l). The vertical
directions `2` and `3` are not supported. (But I don't know of anyone who
actually uses them anyway) Also the corresponding `\vlistdir` is not supported.

To usethis functionality, add `\vlistdirection 1` in addition to your existing
direction settings when switching to r2l mode or `\vlistdirection 0` when
switching to l2r. When doing so, settings to `\bodydirection` and `\pagedirection` can be dropped.
(You probably should still set `\bodydirection` and `\pagedirection` to a proper
global default at the beginning of your document, they still affect the output
routine and  all parts where `\vlistdirection` is no set (aka has value `-"7FFFFFFF`).

## WARNING
This code is a proof of concept and has not been tested with any real documents.
Proceed with caution.
