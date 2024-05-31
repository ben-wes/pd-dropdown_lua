local pdlua_flames = {}
local dropdown = pd.Class:new():register("dropdown-gui")

function dropdown:initialize(name, args)
  self.inlets = 1
  self.outlets = 2

  local methods =
  {
    { name = "fontsize",      defaults = { 11 } },
    { name = "width",         defaults = { 140 } },
    { name = "lineheight",    defaults = { 19 } },

    { name = "fgcolor",      defaults = { 0, 0, 0 } },
    { name = "bgcolor",      defaults = { 255, 255, 255 } },
    { name = "hoverfgcolor", defaults = { 0, 0, 0 } },
    { name = "hoverbgcolor", defaults = { 190, 190, 190 } },
  }

  self.selectedindex = 0
  self.entries = {}
  self.pd_env = { ignorewarnings = true }
  pdlua_flames:init_pd_methods(self, name, methods, args)
  return true
end

function dropdown:postinitialize()
  self:resize()
end

function dropdown:pd_fgcolor(x)
  self:repaint()
end

function dropdown:pd_bgcolor(x)
  self:repaint()
end

function dropdown:pd_hoverfgcolor(x)
  self:repaint()
end

function dropdown:pd_hoverbgcolor(x)
  self:repaint()
end

function dropdown:pd_width(x)
  if type(x[1]) == "number" then
    self.pd_methods.width.val[1] = math.max(8, x[1])
    self:resize()
  end
end

function dropdown:pd_lineheight(x)
  if type(x[1]) == "number" then
    self.pd_methods.lineheight.val[1] = math.max(8, x[1])
    self:resize()
  end
end

function dropdown:pd_fontsize(x)
  if type(x[1]) == "number" then
    self.pd_methods.fontsize.val[1] = math.max(8, x[1])
    self:repaint()
  end
end

function dropdown:in_1_reload()
  self:dofile(self._scriptname)
  pd.post("reloaded")
end

function dropdown:in_1_set(atoms)
  self.selectedindex = 0
  self.highlightedindex = 0
  self.open = false
  self.entries = atoms
  self:resize()
end

function dropdown:in_1_bang()
    self:output_entry()
end

function dropdown:output_entry()
    self:outlet(1, "list", {self.selectedindex-1, self.entries[self.selectedindex]})
end

function dropdown:resize()
  pd.post("resizing")
  if self.open then
    self.height = self.pd_methods.lineheight.val[1]*math.max(1, #self.entries)
  else
    self.height = self.pd_methods.lineheight.val[1]
  end
  self:set_size(self.pd_methods.width.val[1], self.height)
  self:outlet(2, "list", {self.pd_methods.width.val[1], self.height})
  self:repaint()
end

function dropdown:mouse_down(x, y)
  if self.open then
    self.selectedindex = y // self.pd_methods.lineheight.val[1] + 1
    self:output_entry()
  end
  self.open = not self.open
  self:resize()
end

function dropdown:mouse_move(x, y)
  local highlightedindex = y // self.pd_methods.lineheight.val[1] + 1
  if (highlightedindex ~= self.highlightedindex) then
    self.highlightedindex = highlightedindex
    self:repaint()
  end
end

function dropdown:paint(g)
  g:set_color(table.unpack(self.pd_methods.bgcolor.val))
  g:fill_all()
  if self.open then
    for i, entry in ipairs(self.entries) do
      g:set_color(table.unpack(self.pd_methods.fgcolor.val))
      if i==self.highlightedindex then
        g:set_color(table.unpack(self.pd_methods.hoverbgcolor.val))
        g:fill_rect(1, (i-1)*self.pd_methods.lineheight.val[1]+1, self.pd_methods.width.val[1]-1, self.pd_methods.lineheight.val[1]-1)
        g:set_color(table.unpack(self.pd_methods.hoverfgcolor.val))
      end
      g:draw_text(entry, 3, (i-1)*self.pd_methods.lineheight.val[1] + self.pd_methods.lineheight.val[1]*0.5-self.pd_methods.fontsize.val[1]*0.5, self.pd_methods.width.val[1], self.pd_methods.fontsize.val[1])
    end
  else
    g:set_color(table.unpack(self.pd_methods.fgcolor.val))
    g:draw_text(self.entries[math.max(1, self.selectedindex)] or "enter values", 3, self.pd_methods.lineheight.val[1]*0.5-self.pd_methods.fontsize.val[1]*0.5, self.pd_methods.width.val[1], self.pd_methods.fontsize.val[1]) -- or "choose"
    p = Path(self.pd_methods.width.val[1] - self.pd_methods.fontsize.val[1]*0.7, self.pd_methods.lineheight.val[1]*0.5+self.pd_methods.fontsize.val[1]*0.15)
    p:line_to(self.pd_methods.width.val[1] - self.pd_methods.fontsize.val[1]*1.0, self.pd_methods.lineheight.val[1]*0.5-self.pd_methods.fontsize.val[1]*0.3)
    p:line_to(self.pd_methods.width.val[1] - self.pd_methods.fontsize.val[1]*0.4, self.pd_methods.lineheight.val[1]*0.5-self.pd_methods.fontsize.val[1]*0.3)
    g:fill_path(p)
  end
end

function dropdown:in_n(n, sel, atoms)
  if n == 1 then
    self:handle_pd_message(sel, atoms, 1)
  end
end

---------------------------------------------------------------------------------------------

function pdlua_flames:init_pd_methods(pdclass, name, methods, atoms)
  pdclass.handle_pd_message = pdlua_flames.handle_pd_message
  pdclass.pd_env = pdclass.pd_env or {}
  pdclass.pd_env.name = name
  pdclass.pd_methods = {}
  pdclass.pd_args = {}

  local kwargs, args = self:parse_atoms(atoms)
  local argIndex = 1
  for _, method in ipairs(methods) do
    pdclass.pd_methods[method.name] = {}
    -- add method if a corresponding method exists
    local pd_method_name = 'pd_' .. method.name
    if pdclass[pd_method_name] and type(pdclass[pd_method_name]) == 'function' then
      pdclass.pd_methods[method.name].func = pdclass[pd_method_name]
    elseif not pdclass.pd_env.ignorewarnings then
      pdclass:error(name..': no function \'' .. pd_method_name .. '\' defined')
    end
    -- process initial defaults
    if method.defaults then
      -- initialize entry for storing index and arg count and values
      pdclass.pd_methods[method.name].index = argIndex
      pdclass.pd_methods[method.name].arg_count = #method.defaults
      pdclass.pd_methods[method.name].val = method.defaults
      -- populate pd_args with defaults or preset values
      local argValues = {}
      for _, value in ipairs(method.defaults) do
        local addArg = args[argIndex] or value
        pdclass.pd_args[argIndex] = addArg
        table.insert(argValues, addArg)
        argIndex = argIndex + 1
      end
      -- pdclass:handle_pd_message(method.name, argValues)
    end
  end
  for sel, atoms in pairs(kwargs) do
    pdclass:handle_pd_message(sel, atoms)
  end
end

function pdlua_flames:parse_atoms(atoms)
  local kwargs = {}
  local args = {}
  local collectKey = nil
  for _, atom in ipairs(atoms) do
    if type(atom) ~= 'number' and string.sub(atom, 1, 1) == '-' then
      collectKey = string.sub(atom, 2)
      kwargs[collectKey] = {}
    elseif collectKey then
      table.insert(kwargs[collectKey], atom)
    else
      table.insert(args, atom)
    end
  end
  return kwargs, args
end

function pdlua_flames:handle_pd_message(sel, atoms, n)
  if self.pd_methods[sel] then
    local startIndex = self.pd_methods[sel].index
    local valueCount = self.pd_methods[sel].arg_count
    local returnValues = self.pd_methods[sel].func and self.pd_methods[sel].func(self, atoms)
    local values = {}
    if startIndex and valueCount then
      for i, atom in ipairs(returnValues or atoms) do
        if i > valueCount then break end
        table.insert(values, atom)
        self.pd_args[startIndex + i-1] = atom
      end
    end
    self.pd_methods[sel].val = values
    self:set_args(self.pd_args)
  else
    local baseMessage = self.pd_env.name .. ': no method for \'' .. sel .. '\''
    local inletMessage = n and ' on inlet ' .. string.format('%d', n) or ''
    self:error(baseMessage .. inletMessage)
  end
end