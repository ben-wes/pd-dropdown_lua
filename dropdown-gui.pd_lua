local dropdown = pd.Class:new():register("dropdown-gui")

function dropdown:initialize(name, atoms)
    self.inlets = 1
    self.outlets = 2

    self.fontsize = 11
    self.width = 140
    self.lineheight = 16

    self.fgcolor = {0, 0, 0}
    self.bgcolor = {255, 255, 255}
    self.hovercolor = {120, 120, 120}

    self.selectedindex = 0
    self.entries = {}
    return true
end


function dropdown:postinitialize()
    self:resize()
end

function dropdown:in_1_fgcolor(x)
    if #x == 3 and
        type(x[1]) == "number" and
        type(x[2]) == "number" and
        type(x[3]) == "number" then
        self.fgcolor = x
        self:repaint()
    end
end

function dropdown:in_1_bgcolor(x)
    if #x == 3 and
        type(x[1]) == "number" and
        type(x[2]) == "number" and
        type(x[3]) == "number" then
        self.bgcolor = x
        self:repaint()
    end
end

function dropdown:in_1_hovercolor(x)
    if #x == 3 and
        type(x[1]) == "number" and
        type(x[2]) == "number" and
        type(x[3]) == "number" then
        self.hovercolor = x
        self:repaint()
    end
end

function dropdown:resize()
    self:repaint()
    if self.open then
        self.height = self.lineheight*math.max(1, #self.entries)
    else
        self.height = self.lineheight
    end
    self:set_size(self.width, self.height)
    self:outlet(2, "list", {self.width, self.height})
end

function dropdown:in_1_width(x)
  if type(x[1]) == "number" then
    self.width = math.max(8, x[1])
    self:resize()
  end
end

function dropdown:in_1_lineheight(x)
  if type(x[1]) == "number" then
    self.lineheight = math.max(8, x[1])
    self:resize()
  end
end

function dropdown:in_1_fontsize(x)
  if type(x[1]) == "number" then
    self.fontsize = math.max(8, x[1])
    self:repaint()
  end
end

function dropdown:in_1_reload()
    self:dofile(self._scriptname)
    pd.post("reloaded")
end

function dropdown:mouse_down(x, y)
    if self.open then
        self.selectedindex = y // self.lineheight + 1
        self:outlet(1, "list", {self.selectedindex-1, self.entries[self.selectedindex]})
    end
    self.open = not self.open
    self:resize()
end

function dropdown:mouse_move(x, y)
    local highlightedindex = y // self.lineheight + 1
    if (highlightedindex ~= self.highlightedindex) then
        self.highlightedindex = highlightedindex
        self:repaint()
    end
end

function dropdown:in_1_set(atoms)
    self.selectedindex = 0
    self.highlightedindex = 0
    self.open = false
    self.entries = atoms
    self:resize()
end

function dropdown:paint(g)
    g:set_color(table.unpack(self.bgcolor))
    g:fill_all()
    if self.open then
        for i, entry in ipairs(self.entries) do
            g:set_color(table.unpack(self.fgcolor))
            if i==self.highlightedindex then
                g:set_color(table.unpack(self.hovercolor))
                g:fill_rect(1, (i-1)*self.lineheight+1, self.width-1, self.lineheight-1)
                g:set_color(table.unpack(self.bgcolor))
            end
            g:draw_text(entry, 3, (i-1)*self.lineheight + self.lineheight*0.5-self.fontsize*0.5, self.width, self.fontsize)
        end
    else
        g:set_color(table.unpack(self.fgcolor))
        g:draw_text(self.entries[math.max(1, self.selectedindex)] or "enter values", 3, self.lineheight*0.5-self.fontsize*0.5, self.width, self.fontsize) -- or "choose"
        p = Path(self.width - self.fontsize*0.7, self.lineheight*0.5+self.fontsize*0.15)
        p:line_to(self.width - self.fontsize*1.0, self.lineheight*0.5-self.fontsize*0.3)
        p:line_to(self.width - self.fontsize*0.4, self.lineheight*0.5-self.fontsize*0.3)
        g:fill_path(p)
    end
end

function dropdown:in_1_bang()
    self:outlet(1, "list", {self.selectedindex-1, self.entries[self.selectedindex]})
end
