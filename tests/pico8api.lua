-- unlike picolove we don't use LuaJIT, so use bit32 instead of bit
bit = require("bit32")

-- pico-8 api placeholders for tests run under vanilla lua

-- functions taken from gamax92's fork of picolove
-- https://github.com/gamax92/picolove/blob/master/api.lua
-- pico8 table taken from:
-- https://github.com/gamax92/picolove/blob/master/main.lua
-- original repository by Jez Kabanov
-- https://github.com/picolove/picolove
-- both under zlib license
-- see readme.md for more information

pico8={
  fps=60,  -- changed from 30 to 60
  memory_usage=0,
  total_cpu=0,
  system_cpu=0,
  frames=0,
  pal_transparent={},
  resolution={128, 128},
  palette={
    {0,  0,  0,  255},
    {29, 43, 83, 255},
    {126,37, 83, 255},
    {0,  135,81, 255},
    {171,82, 54, 255},
    {95, 87, 79, 255},
    {194,195,199,255},
    {255,241,232,255},
    {255,0,  77, 255},
    {255,163,0,  255},
    {255,240,36, 255},
    {0,  231,86, 255},
    {41, 173,255,255},
    {131,118,156,255},
    {255,119,168,255},
    {255,204,170,255}
  },
  spriteflags={},
  audio_channels={},
  sfx={},
  music={},
  current_music=nil,
  usermemory={},
  cartdata={},
  clipboard="",
  keypressed={
    [0]={},
    [1]={},
    counter=0
  },
  kbdbuffer={},
  keymap={
    [0]={
      [0]={'left'},
      [1]={'right'},
      [2]={'up'},
      [3]={'down'},
      [4]={'z', 'n'},
      [5]={'x', 'm'},
    },
    [1]={
      [0]={'s'},
      [1]={'f'},
      [2]={'e'},
      [3]={'d'},
      [4]={'tab', 'lshift'},
      [5]={'q', 'a'},
    }
  },
  mousepos={  -- simulate mouse position
    x=0,
    y=0
  },
  mousebtnpressed={  -- simulate mouse buttons
    false,
    false,
    false
  },
  mwheel=0,
  cursor={0, 0},
  camera_x=0,
  camera_y=0,
  draw_palette={},
  display_palette={},
  pal_transparent={},
  map={},  -- should be initialized with 0 or game data, but ok for tests
  poked_addresses={}  -- not a complete simulation of memory, just of poked addresses set to value
}

local function getMouseX()
  return pico8.mousepos.x
end

local function getMouseY()
  return pico8.mousepos.y
end

local function warning(msg)
  print(debug.traceback("WARNING: "..msg, 3))
end

function camera(x, y)
  if x~=nil then
    pico8.camera_x=flr(x)
    pico8.camera_y=flr(y)
  else
    pico8.camera_x=0
    pico8.camera_y=0
  end
end

function clip(x, y, w, h)
  if x and y and w and h then
    pico8.clip={x, y, w, h}
  else
    pico8.clip=nil
  end
end

function cls(c)
  c = tonumber(c) or 0
  if c == nil then
    c = 0
  end

  pico8.clip=nil
  pico8.cursor={0, 0}
end

function pset(x, y, c)
  if c then
    color(c)
  end
end

function pget(x, y)
  return 0
end

function color(c)
  c=flr(c or 0)%16
  pico8.color=c
end

function cursor(x, y)
  pico8.cursor={x or 0, y or 0}
end

function tonum(val)
  return tonumber(val) -- not a direct assignment to prevent usage of the radix argument
end

function tostr(val, hex)
  local kind=type(val)
  if kind == "string" then
    return val
  elseif kind == "number" then
    if hex then
      val=val*0x10000
      local part1=bit.rshift(bit.band(val, 0xFFFF0000), 4)
      local part2=bit.band(val, 0xFFFF)
      return string.format("0x%04x.%04x", part1, part2)
    else
      return tostring(val)
    end
  elseif kind == "boolean" then
    return tostring(val)
  else
    return "[" .. kind .. "]"
  end
end

function spr(n, x, y, w, h, flip_x, flip_y)
end

function sspr(sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y)
end

function rect(x0, y0, x1, y1, col)
  if col then
    color(col)
  end
end

function rectfill(x0, y0, x1, y1, col)
  if col then
    color(col)
  end
end

function circ(ox, oy, r, col)
  if col then
    color(col)
  end
end

function circfill(cx, cy, r, col)
  if col then
    color(col)
  end
end

function line(x0, y0, x1, y1, col)
  if col then
    color(col)
  end
end

function pal(c0, c1, p)
  if c0==nil then
    for i=0, 15 do
      if pico8.draw_palette[i]~=i then
        pico8.draw_palette[i]=i
      end
      if pico8.display_palette[i]~=pico8.palette[i+1] then
        pico8.display_palette[i]=pico8.palette[i+1]
      end
      local alpha=i==0 and 0 or 1
      if pico8.pal_transparent[i]~=alpha then
        pico8.pal_transparent[i]=alpha
      end
    end
  elseif p==1 and c1~=nil then
    c0=flr(c0)%16
    c1=flr(c1)%16
    if pico8.draw_palette[c0]~=pico8.palette[c1+1] then
      pico8.display_palette[c0]=pico8.palette[c1+1]
    end
  elseif c1~=nil then
    c0=flr(c0)%16
    c1=flr(c1)%16
    if pico8.draw_palette[c0]~=c1 then
      pico8.draw_palette[c0]=c1
    end
  end
end

function palt(c, t)
  if c==nil then
    for i=0, 15 do
      pico8.pal_transparent[i]=i==0 and 0 or 1
    end
  else
    c=flr(c)%16
    pico8.pal_transparent[c]=t and 0 or 1
  end
end

function fillp(p)
end

function map(cel_x, cel_y, sx, sy, cel_w, cel_h, bitmask)
end

function mget(x, y)
  x=flr(x or 0)
  y=flr(y or 0)
  if x>=0 and x<128 and y>=0 and y<64 then
    return pico8.map[y][x]  -- will be nil if not set in test before
  end
  return 0
end

function mset(x, y, v)
  x=flr(x or 0)
  y=flr(y or 0)
  v=flr(v or 0)%256
  if x>=0 and x<128 and y>=0 and y<64 then
    pico8.map[y][x]=v
  end
end

function fget(n, f)
  if n==nil then return nil end
  if f~=nil then
    -- return just that bit as a boolean
    if not pico8.spriteflags[flr(n)] then
      warning(string.format('fget(%d, %d)', n, f))
      return false
    end
    return bit.band(pico8.spriteflags[flr(n)], bit.lshift(1, flr(f)))~=0
  end
  return pico8.spriteflags[flr(n)] or 0
end

function fset(n, f, v)
  -- fset n [f] v
  -- f is the flag index 0..7
  -- v is boolean
  if v==nil then
    v, f=f, nil
  end
  if f then
    -- set specific bit to v (true or false)
    if v then
      pico8.spriteflags[n]=bit.bor(pico8.spriteflags[n], bit.lshift(1, f))
    else
      pico8.spriteflags[n]=bit.band(pico8.spriteflags[n], bit.bnot(bit.lshift(1, f)))
    end
  else
    -- set bitfield to v (number)
    pico8.spriteflags[n]=v
  end
end

function sget(x, y)
  return 0
end

function sset(x, y, c)
end

function music(n, fadems, channel_mask)
  n = n or -1
  if n < -1 then
    n = 0
  end
  if n >= 0 then
    -- simulate music currently played
    -- this will be correct for a looping music (without knowing the used channels and current play time)
    -- however for a non-looping music we won't detect when the music is supposed to end in integration tests
    fadems = fadems or 0
    channel_mask = channel_mask or 0
    pico8.current_music={music=n, fadems=fadems, channel_mask=channel_mask}
  else
    pico8.current_music = nil
  end
end

function sfx(n, channel, offset)
  -- most sfx are non-looping so it's not so useful to have a current sfx, and it's tedious
  -- to keep a list of played sfx history, so we just do nothing and will spy on sfx if needed
end

function peek(addr)
  return pico8.poked_addresses[addr]
end

function poke(addr, val)
  pico8.poked_addresses[addr] = val
end

function peek4(addr)
  local val = 0
  val = val + peek(addr+0)/0x10000
  val = val + peek(addr+1)/0x100
  val = val + peek(addr+2)
  val = val + peek(addr+3)*0x100
  return val
end

function poke4(addr, val)
  val=val*0x10000
  poke(addr+0, bit.rshift(bit.band(val, 0x000000FF),  0))
  poke(addr+1, bit.rshift(bit.band(val, 0x0000FF00),  8))
  poke(addr+2, bit.rshift(bit.band(val, 0x00FF0000), 16))
  poke(addr+3, bit.rshift(bit.band(val, 0xFF000000), 24))
end

function memcpy(dest_addr, source_addr, len)
  if len<1 or dest_addr==source_addr then
    return
  end

  -- Screen Hack (removed)

  local offset=dest_addr-source_addr
  if source_addr>dest_addr then
    for i=dest_addr, dest_addr+len-1 do
      poke(i, peek(i-offset))
    end
  else
    for i=dest_addr+len-1, dest_addr, -1 do
      poke(i, peek(i-offset))
    end
  end
  -- __scrimg and __scrblit
end

function memset(dest_addr, val, len)
  if len<1 then
    return
  end
  for i=dest_addr, dest_addr+len-1 do
    poke(i, val)
  end
end

function reload(dest_addr, source_addr, len)
end

function cstore(dest_addr, source_addr, len)
end

function rnd(x)
  return math.random()*(x or 1)
end

function srand(seed)
  math.randomseed(flr(seed*0x10000))
end

flr=math.floor
ceil=math.ceil

function sgn(x)
  return x<0 and-1 or 1
end

abs=math.abs

function min(a, b)
  if a==nil or b==nil then
    warning('min a or b are nil returning 0')
    return 0
  end
  if a<b then return a end
  return b
end

function max(a, b)
  if a==nil or b==nil then
    warning('max a or b are nil returning 0')
    return 0
  end
  if a>b then return a end
  return b
end

function mid(x, y, z)
  return (x<=y)and((y<=z)and y or((x<z)and z or x))or((x<=z)and x or((y<z)and z or y))
end

function cos(x)
  return math.cos((x or 0)*math.pi*2)
end

function sin(x)
  return-math.sin((x or 0)*math.pi*2)
end

sqrt=math.sqrt

function atan2(x, y)
  return (0.75 + math.atan2(x,y) / (math.pi * 2)) % 1.0
end

function band(x, y)
  return bit.band(x*0x10000, y*0x10000)/0x10000
end

function bor(x, y)
  return bit.bor(x*0x10000, y*0x10000)/0x10000
end

function bxor(x, y)
  return bit.bxor(x*0x10000, y*0x10000)/0x10000
end

function bnot(x)
  return bit.bnot(x*0x10000)/0x10000
end

function shl(x, y)
  return bit.lshift(x*0x10000, y)/0x10000
end

function shr(x, y)
  return bit.arshift(x*0x10000, y)/0x10000
end

function lshr(x, y)
  return bit.rshift(x*0x10000, y)/0x10000
end

function rotl(x, y)
  return bit.rol(x*0x10000, y)/0x10000
end

function rotr(x, y)
  return bit.ror(x*0x10000, y)/0x10000
end

function time()
  return pico8.frames/30
end
t=time

function btn(i, p)
  if i~=nil or p~=nil then
    p=p or 0
    if p<0 or p>1 then
      return false
    end
    return not not pico8.keypressed[p][i]
  else
    local bits=0
    for i=0, 5 do
      bits=bits+(pico8.keypressed[0][i] and 2^i or 0)
      bits=bits+(pico8.keypressed[1][i] and 2^(i+8) or 0)
    end
    return bits
  end
end

function btnp(i, p)
  if i~=nil or p~=nil then
    p=p or 0
    if p<0 or p>1 then
      return false
    end
    local init=(pico8.fps/2-1)
    local v=pico8.keypressed.counter
    if pico8.keypressed[p][i] and (v==init or v==1) then
      return true
    end
    return false
  else
    local init=(pico8.fps/2-1)
    local v=pico8.keypressed.counter
    if not (v==init or v==1) then
      return 0
    end
    local bits=0
    for i=0, 5 do
      bits=bits+(pico8.keypressed[0][i] and 2^i or 0)
      bits=bits+(pico8.keypressed[1][i] and 2^(i+8) or 0)
    end
    return bits
  end
end

function cartdata(id)
end

function dget(index)
  index=flr(index)
  if index<0 or index>63 then
    warning('cartdata index out of range')
    return
  end
  return pico8.cartdata[index]
end

function dset(index, value)
  index=flr(index)
  if index<0 or index>63 then
    warning('cartdata index out of range')
    return
  end
  pico8.cartdata[index]=value
end

local tfield={[0]="year", "month", "day", "hour", "min", "sec"}
function stat(x)
  if x == 0 then
    return pico8.memory_usage
  elseif x == 1 then
    return pico8.total_cpu
  elseif x == 2 then
    return pico8.system_cpu
  elseif x == 4 then
    return pico8.clipboard
  elseif x == 7 then
    return pico8.fps
  elseif x == 8 then
    return pico8.fps
  elseif x == 9 then
    return pico8.fps
  elseif x >= 16 and x <= 23 then
    local ch=pico8.audio_channels[x%4]
    if not ch.sfx then
      return -1
    elseif x < 20 then
      return ch.sfx
    else
      return flr(ch.offset)
    end
  elseif x == 30 then
    return #pico8.kbdbuffer ~= 0
  elseif x == 31 then
    return (table.remove(pico8.kbdbuffer, 1) or "")
  elseif x == 32 then
    return getMouseX()
  elseif x == 33 then
    return getMouseY()
  elseif x == 34 then
    local btns=0
    for i=0, 2 do
      if pico8.mousebtnpressed[i+1] then
        btns=bit.band(btns, bit.lshift(1, i))
      end
    end
    return btns
  elseif x == 36 then
    return pico8.mwheel
  elseif (x >= 80 and x <= 85) or (x >= 90 and x <= 95) then
    local tinfo
    if x < 90 then
      tinfo = os.date("!*t")
    else
      tinfo = os.date("*t")
    end
    return tinfo[tfield[x%10]]
  elseif x == 100 then
    return nil -- TODO: breadcrumb not supported
  end
  return 0
end

function holdframe()
end

sub=string.sub
cocreate=coroutine.create
coresume=coroutine.resume
yield=coroutine.yield
costatus=coroutine.status
trace=debug.traceback

-- The functions below are normally attached to the program code, but are here for simplicity
function all(a)
  if a==nil or #a==0 then
    return function() end
  end
  local i, li=1
  return function()
    if (a[i]==li) then i=i+1 end
    while(a[i]==nil and i<=#a) do i=i+1 end
    li=a[i]
    return a[i]
  end
end

function foreach(a, f)
  for v in all(a) do
    f(v)
  end
end

function count(a)
  local count=0
  for i=1, #a do
    if a[i]~=nil then count=count+1 end
  end
  return count
end

function add(a, v)
  if a==nil then return end
  a[#a+1]=v
end

function del(a, dv)
  if a==nil then return end
  for i=1, #a do
    if a[i]==dv then
      table.remove(a, i)
      return
    end
  end
end

-- printh must not refer to the native print directly
-- because params are different and to avoid spying on
-- the wrong calls (busted -o TAP may print natively)
function printh(str, filename, overwrite)
  -- file writing is not supported in tests
  print(str)
end

api = {}

-- only print is defined under api to avoid overriding native print
-- (used by busted -o TAP)
-- note that runtime code will need to define api.print
function api.print(str, x, y, col)
  if col then
    color(col)
  end
  if x and y then
    pico8.cursor[1]=flr(tonumber(x) or 0)
    pico8.cursor[2]=flr(tonumber(y) or 0)
  end
  local str=tostring(str):gsub("[%z\1-\9\11-\31\154-\255]", " "):gsub("[\128-\153]", "\194%1").."\n"
  local size=0
  for line in str:gmatch("(.-)\n") do
    size=size+6
  end
  if not x and not y then
    if pico8.cursor[2]+size>122 then
    else
      pico8.cursor[2]=pico8.cursor[2]+size
    end
  end
end
