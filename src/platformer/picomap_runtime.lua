-- Runtime PicoMap loading methods based on picomap v0.42 testcart by jadelombax
-- https://www.lexaloffle.com/bbs/?tid=42848&pid=91798

-- USAGE

-- pal(15,137,1) --dark orange for ground

-- function _init()
--  fg_array={}
--  lvlnum=1
--  bp=32
--  move_data()
--  decompress(sprites,sset)
--  decompress(map_mem,mset)
-- end

-- function _update60()
--  if bp>15 then
--   build_array(fg_array,lvlnum) fgw,fgh=lvl_width,lvl_ht
--   camx,camy=0,0
--  end
--  bp,bn=btnp(),btn()

--  camx=mid(0,camx+(bn\2%2-bn%2)*2,fgw*8-128)
--  camy=mid(0,camy+(bn\8%2-bn\4%2)*2,fgh*8-screen_ht*8)
--  lvlnum=mid(1,lvlnum+bp\32%2-bp\16%2,#loc_tbl-1)

--  cls(bgc)
--  map_array(fg_array,1,0,0)
-- end
-->8
--sys.functions w/autotiling
--(814 tokens)

-- z8lua candidate: restore original shortcut code to spare tokens/chars

function move_data()
 map_tbl={}
 for i=0,8191 do
  add(map_tbl,int_div(peek(i),16))
  add(map_tbl,peek(i)%16)
 end
end

function decompress(str,set)
 local n,w,k=0,ord(str,1,2)
 local k=0
 printh("k: "..nice_dump(k))
 for i=3,#str do
  local v=255-ord(str,i)
  for l=0,int_div(v,16^k) do
   set(n%w,int_div(n,w),v) n=n+1
  end
 end
end

function build_array(array,lvlnum)
 screen_num,screen_ht,bops,map_obs=0,ord(def_str,1,3)
 --lvl data loc.,autotile bit tbl,autotile bit
 local l,atb,atbit=loc_tbl[lvlnum],0,{}
 --reads table values
 local function t(n)
  local q=int_div(n,2)
  local v=map_tbl[l]*16^q+map_tbl[l+1]*q
  l=l+n
  return v
 end
 --lvl header
 lvl_type,bgc,lvl_width,lvl_ht,bgtile=t'1',t'1',t'2'*16+16,t'2'*screen_ht+screen_ht,t'2'
 --create array
 local function create(s,e,v)
  for row=s,lvl_ht+e do
  if s==0 then array[row]={} end
   for col=s,lvl_width+e do
    array[row][col]=v
   end
  end
 end
 -- CHANGED: luamin uses old luaparse which fails on hexadecimal
 -- create(0,2,0x.3f)
 create(0,2,tonumber("0x.3f"))
 create(2,1,bgtile)
 while l<loc_tbl[lvlnum+1]-1 do

  obnum,screen_num_b=t'2'
  --next screen flag
  if obnum==233 then
   screen_num=screen_num+1 obnum=t'2'
  --screen jump & return
  elseif obnum==234 then
   screen_num_b,screen_num,obnum=screen_num,t'2',t'2'
  --screen jump
  elseif obnum==235 then
   screen_num,obnum=t'2',t'2'
  end
  --obj position
  local xpos,ypos=t'1',t'1'
  local xp=xpos+screen_num*16
  --obj def data
  local scx,scy,ds,vi=ord(def_str,obnum*4+4,4)
  local dw,dh,typ,ati,draw=int_div(ds,16)+1,ds%16+1,int_div(vi,16),(vi%16&1)/2,1
  --obj type traits
  local tbl,mso,k={},int_div(typ,13),split"¹¹²¹³³,⁷¹²¹³³,¹⁷²¹³³,⁷⁷²¹³³,⁷⁷¹¹²²,⁷¹¹¹⁵⁶,¹⁷¹¹⁵⁶,⁷⁷¹¹⁵⁶,_,⁷¹¹²⁴⁴,¹⁷¹²⁴⁴,⁷⁷¹²⁴⁴,_,⁷¹¹¹⁵⁶,¹⁷¹¹⁵⁶,⁷⁷¹¹⁵⁶"[typ+1]
  for n=1,6 do
   z=ord(k,n)
   -- CHANGED: LuaParse fails on this line, had to split in two
   -- pico8.lua.parser.ParserError: token TokSymbol<b')', line 54 char 48> does not match keyword nor symbol b'[' at line 55 char 48
   -- add(tbl,({0,1,256,bops,dw,dh,t(int_div(z,7))})[z])
   tbl2={0,1,256,bops,dw,dh,t(int_div(z,7))}
   add(tbl,tbl2[z])
  end
  xv,yv,sb,eb,psx,psy=unpack(tbl)
  --total obj w&h
  local tw,th=max(dw+xv,xv*16*mso)-1,max(dh+yv,yv*screen_ht*mso)-1
  --if entity obj
--   if obnum>map_obs then
--    draw=_
--   end
  if draw then
   --x&y start pos.
   local sx,sy=xp%lvl_width,ypos+int_div(xp,lvl_width)*screen_ht
   for x=0,tw do
    for y=0,th do
     local px,py,ax,ay=(x-dw)%psx,(y-dh)%psy,sx+x+2,sy+y+2
     local tile=mget(scx+(x>=dw and sb*dw+px+eb*(int_div(x,tw)*(psx-px)+dw) or x),scy+(y>=dh and sb*dh+py+eb*(int_div(y,th)*(psy-py)+dh) or y))
     if array[ay] and array[ay][ax] then
      if tile>0 then
       if tonum(at_list[tile]) and not atbit[tile] then
        atbit[tile]=.125>>atb
        atb=atb+1
       end
       array[ay][ax]=tile+ati+array[ay][ax]%.5|(atbit[tile] or 0)
      end
     end
    end
    screen_num=screen_num_b or screen_num
   end
  end
 end
 --autotiling
 for y=1,lvl_ht do
  for x=1,lvl_width do
   local tile=int_div(array[y+1][x+1],1)
   local v1,v2,n=tonum(at_list[tile]),atbit[tile],256
   if v1 then
    for i=0,8 do
     local id=array[y+int_div(i,3)][x+i%3]
     if int_div(id,1)~=tile and id&.5>0 or id&v2==0 then
      n=n+ord("▮¹ ²\0⁴@⁸█",i+1)
     end
    end
    local btx,bty,nto=v1&127,int_div(v1,128),ord("ᶜ⁷ᵇ⁶\r⁸\n⁵■²▮¹□³ᶠ\0ᶜ⁴	ᶜ⁙ᶜᶜᶜᵉᶜᶜᶜᶜᶜᶜᶜ",(n%16<1 and int_div(n,16) or n%16)+1)
    tile=mget(btx+nto%5,bty+int_div(nto,5))
   end
   array[y-1][x-1]=tile
  end
 end
end

function map_array(array,scroll_coef,x_offset,y_offset)
 local ht,w,cx,cy=#array-2,#array[1]-2,camx*scroll_coef,camy*scroll_coef
 local px,py=int_div(cx,8)+x_offset,int_div(cy,8)+y_offset
 for row=0,screen_ht do
  local r=(row+py)%ht
  for col=0,16 do
   mset(111+col,row,array[r][(col+px)%w])
  end
 end
 map(111,0,-(cx%8),-(cy%8))
end
-->8
--sys.functions w/o autotiling
--(586 tokens)

--function move_data()
-- map_tbl={}
-- for i=0,8191 do
--  add(map_tbl,@i\16)
--  add(map_tbl,@i%16)
-- end
--end
--
--function decompress(str,set)
-- local n,w,k=0,ord(str,1,2)
-- for i=3,#str do
--  local v=255-ord(str,i)
--  for l=0,v\16^k do
--   set(n%w,n\w,v) n+=1
--  end
-- end
--end
--
--function build_array(array,lvlnum)
-- screen_num,screen_ht,bops,map_obs=0,ord(def_str,1,3)
-- --lvl data loc.
-- local l=loc_tbl[lvlnum]
-- --reads table values
-- local function t(n)
--  local q=n\2
--  local v=map_tbl[l]*16^q+map_tbl[l+1]*q
--  l+=n
--  return v
-- end
-- --lvl header
-- lvl_type,bgc,lvl_width,lvl_ht,bgtile=t'1',t'1',t'2'*16+16,t'2'*screen_ht+screen_ht,t'2'
-- --create array
-- for row=0,lvl_ht do
--  array[row]={}
--  for col=0,lvl_width do
--   array[row][col]=bgtile
--  end
-- end
-- while l<loc_tbl[lvlnum+1]-1 do
--
--  obnum,screen_num_b=t'2'
--  --next screen flag
--  if obnum==233 then
--   screen_num+=1 obnum=t'2'
--  --screen jump & return
--  elseif obnum==234 then
--   screen_num_b,screen_num,obnum=screen_num,t'2',t'2'
--  --screen jump
--  elseif obnum==235 then
--   screen_num,obnum=t'2',t'2'
--  end
--  --obj position
--  local xpos,ypos=t'1',t'1'
--  local xp=xpos+screen_num*16
--  --obj def data
--  local scx,scy,ds,vi=ord(def_str,obnum*4+4,4)
--  local dw,dh,typ,draw=ds\16+1,ds%16+1,vi\16,1
--  --obj type traits
--  local tbl,mso,k={},typ\13,split"¹¹²¹³³,⁷¹²¹³³,¹⁷²¹³³,⁷⁷²¹³³,⁷⁷¹¹²²,⁷¹¹¹⁵⁶,¹⁷¹¹⁵⁶,⁷⁷¹¹⁵⁶,_,⁷¹¹²⁴⁴,¹⁷¹²⁴⁴,⁷⁷¹²⁴⁴,_,⁷¹¹¹⁵⁶,¹⁷¹¹⁵⁶,⁷⁷¹¹⁵⁶"[typ+1]
--  for n=1,6 do
--   z=ord(k,n)
--   add(tbl,({0,1,256,bops,dw,dh,t(z\7)})[z])
--  end
--  xv,yv,sb,eb,psx,psy=unpack(tbl)
--  --total obj w&h
--  local tw,th=max(dw+xv,xv*16*mso)-1,max(dh+yv,yv*screen_ht*mso)-1
--  --if entity obj
----   if obnum>map_obs then
----    draw=_
----   end
--  if draw then
--   --x&y start pos.
--   local sx,sy=xp%lvl_width,ypos+xp\lvl_width*screen_ht
--   for x=0,tw do
--    for y=0,th do
--     local px,py,ax,ay=(x-dw)%psx,(y-dh)%psy,sx+x,sy+y
--     local tile=mget(scx+(x>=dw and sb*dw+px+eb*(x\tw*(psx-px)+dw) or x),scy+(y>=dh and sb*dh+py+eb*(y\th*(psy-py)+dh) or y))
--     if array[ay] and array[ay][ax] then
--      if tile>0 then
--       array[ay][ax]=tile
--      end
--     end
--    end
--    screen_num=screen_num_b or screen_num
--   end
--  end
-- end
--end
--
--function map_array(array,scroll_coef,x_offset,y_offset)
-- local ht,w,cx,cy=#array,#array[1],camx*scroll_coef,camy*scroll_coef
-- local px,py=cx\8+x_offset,cy\8+y_offset
-- for row=0,screen_ht do
--  local r=(row+py)%ht
--  for col=0,16 do
--   mset(111+col,row,array[r][(col+px)%w])
--  end
-- end
-- map(111,0,-(cx%8),-(cy%8))
--end

-->8
--array fget function
--(substitute for fget(mget)
--for map collision, making sure
--array referenced is the
--foreground array in your
--project)

--function afget(x,y,n)
-- local ay,ax=array[y\1],x\1
-- return ay and ay[ax] and fget(ay[ax]&255,n) or false
--end

-->8
--data strings
--(press ctrl+p for "puny font
--mode" before pasting)
