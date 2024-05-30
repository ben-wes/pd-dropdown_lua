## Installation
Files should be placed in Pd's external folder in additional `dropdown_lua` subfolder. Requires ELSE library or `pdlua` for lua support.

## Usage
Create `dropdown_lua` object. For message examples, see help patch.

## Todos
This is currently just a very basic experiment and still completely unfinished:
* state management for parameters missing
* can't handle lists in single entry line
* no automatic width adjustment
* should probably have fgcolor and bgcolor for highlighted line
* possibly selection should be applied on `mouse_up` at some point
* transitions?
* more elegant code?
