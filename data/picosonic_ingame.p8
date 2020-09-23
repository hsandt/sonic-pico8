pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- pico-sonic
-- by hsandt
package={a={},_c={}}package._c["engine/pico8/api"]=function()api={print=print}end
package._c["engine/common"]=function()require("engine/application/constants")require("engine/render/color")require("engine/core/helper")require("engine/core/class")require("engine/core/math")require("engine/debug/dump")end
package._c["engine/application/constants"]=function()screen_width=128
screen_height=128
tile_size=8
character_width=4
character_height=6
fps60=60
fps30=30
delta_time60=0x0000.0444
delta_time30=0x0000.0888 end
package._c["engine/render/color"]=function()colors={b=0,c=1,d=2,e=3,f=4,g=5,h=6,i=7,j=8,k=9,l=10,m=11,n=12,o=13,p=14,q=15}color_strings={[0]="black","dark_blue","dark_purple","dark_green","brown","dark_gray","light_gray","white","red","orange","yellow","green","blue","indigo","pink","peach"}function color_tostring(r)return color_strings[r]or"unknown color"end
function set_unique_transparency(r)palt()palt(0,false)palt(r,true)end end
package._c["engine/core/helper"]=function()function transform(t,s)local u={}for v,w in pairs(t)do u[v]=s(w)end
return u end
function contains(t,x)for v,w in pairs(t)do if w==x then return true end end
return false end
function is_empty(t)for y,z in pairs(t)do return false end
return true end
function clear_table(t)for y in pairs(t)do t[y]=nil end end
function yield_delay(A)for B=1,A-1 do yield()end end end
package._c["engine/core/class"]=function()local function C(cls,...)local self=setmetatable({},cls)self:D(...)return self end
local function E(F,G)return stringify(F)..stringify(G)end
local function H(self)local I=setmetatable({},getmetatable(self))for v,w in pairs(self)do local J=false
if type(w)=='table'and not J then I[v]=w:H()else I[v]=w end end
return I end
local function K(self,L)for v,w in pairs(L)do if type(w)=='table'then self[v]=w:H()else self[v]=w end end end
function new_class()local M={}M.__index=M
M.__concat=E
setmetatable(M,{__call=C})return M end
function derived_class(N)local M={}M.__index=M
M.__concat=E
setmetatable(M,{__index=N,__call=C})return M end
function new_struct()local O={}O.__index=O
O.__concat=E
O.H=H
O.K=K
setmetatable(O,{__call=C})return O end
function derived_struct(P)local Q={}Q.__index=Q
Q.__concat=E
setmetatable(Q,{__index=P,__call=C})return Q end
function singleton(D)local R={}setmetatable(R,{__concat=E})R.D=D
R:D()return R end
function derived_singleton(S,T)local U={}setmetatable(U,{__index=S,__concat=E})function U:D()S.D(self)if T then T(self)end end
U:D()return U end end
package._c["engine/core/math"]=function()huge=1/0
function int_div(V,W)return flr(V/W)end
tile_vector=new_struct()function tile_vector:D(X,Y)self.X=X
self.Y=Y end
function tile_vector:_tostring()return"tile_vector("..(self.X..(", "..(self.Y..")")))end
function tile_vector:Z()return vector(8*self.X,8*self.Y)end
sprite_id_location=derived_struct(tile_vector)function sprite_id_location:_tostring()return"sprite_id_location("..(self.X..(", "..(self.Y..")")))end
function sprite_id_location:_()return 16*self.Y+self.X end
function sprite_id_location.a0(a1)return sprite_id_location(a1%16,int_div(a1,16))end
location=derived_struct(tile_vector)function location.__eq(F,G)return F.X==G.X and F.Y==G.Y end
function location:_tostring()return"location("..(self.X..(", "..(self.Y..")")))end
function location:a2()return vector(8*self.X+4,8*self.Y+4)end
function location.__add(F,G)return location(F.X+G.X,F.Y+G.Y)end
vector=new_struct()function vector:D(a3,a4)self.a3=a3
self.a4=a4 end
function vector.__eq(F,G)return vector.a5(F-G)end
function vector:_tostring()return"vector("..(self.a3 ..(", "..(self.a4 ..")")))end
function vector:a6(a7)return a7=="x"and self.a3 or self.a4 end
function vector:a8(a7,w)if a7=="x"then self.a3=w else self.a4=w end end
function vector.__add(F,G)return vector(F.a3+G.a3,F.a4+G.a4)end
function vector:a9(aa)self:K(self+aa)end
function vector.__sub(F,G)return F+-G end
function vector:ab(aa)self:K(self-aa)end
function vector.__unm(z)return-1*z end
function vector.__mul(F,G)if getmetatable(G)then return vector(F*G.a3,F*G.a4)else return G*F end end
function vector:ac(ad)self:K(self*ad)end
function vector.__div(F,G)return F*(1/G)end
function vector:ae(ad)self:K(self/ad)end
function vector:af(aa)return self.a3*aa.a3+self.a4*aa.a4 end
function vector:ag()return self:af(self)end
function vector:a5()return self:ag()==0 end
function vector.ah()return vector(0,0)end
function vector:ai()return location(flr(self.a3/tile_size),flr(self.a4/tile_size))end
directions={aj=0,ak=1,al=2,am=3}dir_vectors={[0]=vector(-1.,0.),vector(0.,-1.),vector(1.,0.),vector(0.,1.)}horizontal_dirs={aj=1,al=2}vertical_dirs={ak=1,am=2}horizontal_dir_vectors={vector(-1.,0.),vector(1.,0.)}horizontal_dir_signs={-1,1}function signed_speed_to_dir(an)return an<0 and horizontal_dirs.aj or horizontal_dirs.al end
function oppose_dir(ao)return(ao+2)%4 end end
package._c["engine/debug/dump"]=function()require("engine/core/string")function stringify(w)if type(w)=='table'and w._tostring then return w:_tostring()else return tostr(w)end end
local function ap(t)local aq={}for v in pairs(t)do table.ar(aq,v)end
table.as(aq)return aq end
local function at(t,au)local v=nil
if au==nil then t.__orderedIndex=ap(t)v=t.__orderedIndex[1]else for X=1,#t.__orderedIndex do if t.__orderedIndex[X]==au then v=t.__orderedIndex[X+1]end end end
if v then return v,t[v]end
t.__orderedIndex=nil
return end
function orderedPairs(t)return at,t,nil end
function dump(av,aw,ax,ay,az)if aw==nil then aw=false end
ax=ax or 2
if ay==nil then ay=false end
if az==nil then az=false end
local aA
if type(av)=="table"then if ay and av._tostring then aA=av:_tostring()else if ax>0 then local aB={}local aC
if az then aC=orderedPairs else aC=pairs end
for v,w in aC(av)do local aD=dump(v,true,ax-1,ay,az)local aE=dump(w,false,ax-1,ay,az)add(aB,aD..(" = "..aE))end
aA="{"..(joinstr_table(", ",aB).."}")else return"[table]"end end else aA=tostr(av)end
if(aw and type(av)~="string")and sub(aA,1,1)~="["then aA="["..(aA.."]")elseif not aw and type(av)=="string"then aA="\""..(aA.."\"")end
return aA end
function nice_dump(w,az)return dump(w,false,nil,true,az)end
function dump_sequence(aF)return"{"..(joinstr_table(", ",aF,nice_dump).."}")end end
package._c["engine/core/string"]=function()local aG={}local aH="ABCDEFGHIJKLMNOPQRSTUVWXYZ"local aI="abcdefghijklmnopqrstuvwxyz"for X=1,26 do aG[sub(aH,X,X)]=sub(aI,X,X)end
function to_big(aJ)local aK=""for X=1,#aJ do local aL=sub(aJ,X,X)if aL>="A"and aL<="Z"then aK=aK..aG[aL]else aK=aK..aL end end
return aK end
function joinstr_table(aM,aN,aO)aO=aO or stringify
local a1=#aN
local aP=""for aQ=1,a1 do aP=aP..aO(aN[aQ])if aQ<a1 then aP=aP..aM end end
return aP end
function joinstr(aM,...)return joinstr_table(aM,{...})end
function wwrap(R,aR)local aS=''local aT=strspl(R,'\n')local nb_lines=count(aT)for X=1,nb_lines do local aU=0
local aV=strspl(aT[X],' ')local aW=count(aV)for y=1,aW do local aX=aV[y]local aY=false
if y>1 then if(aU+1)+#aX>aR then aS=aS..'\n'aU=0
aY=true else aS=aS..' 'aU=aU+1 end end
aS=aS..aX
aU=aU+#aX end
if X<nb_lines then aS=aS..'\n'end end
return aS end
function compute_char_size(aZ)local aT=strspl(aZ,'\n')nb_lines=#aT
local a_=0
for line in all(aT)do a_=max(a_,#line)end
return a_,nb_lines end
function compute_size(aZ)local a_,nb_lines=compute_char_size(aZ)return a_*character_width+1,nb_lines*character_height+1 end
function strspl(R,b0,b1)local b2={}local b3=""for X=1,#R do local aL=sub(R,X,X)local b4=type(b0)=="table"and contains(b0,aL)or aL==b0
if b4 then if#b3>0 or not b1 then add(b2,b3)b3=""end else b3=b3 ..aL end end
if#b3>0 or not b1 then add(b2,b3)end
return b2 end end
package._c["common"]=function()require("engine/core/direction_ext")require("engine/core/vector_ext")end
package._c["engine/core/direction_ext"]=function()function mirror_dir_x(ao)if ao==directions.aj then return directions.al elseif ao==directions.al then return directions.aj else return ao end end
function mirror_dir_y(ao)if ao==directions.ak then return directions.am elseif ao==directions.am then return directions.ak else return ao end end
function rotate_dir_90_cw(ao)return(ao+1)%4 end
function rotate_dir_90_ccw(ao)return(ao-1)%4 end end
package._c["engine/core/vector_ext"]=function()function vector.b5(b6)return vector(cos(b6),sin(b6))end
function vector:b7()return sqrt(self:ag())end
function vector:b8()local b7=self:b7()return b7>0 and self/b7 or vector.ah()end
function vector:b9()self:K(self:b8())end
function vector:ba(bb)local b7=self:b7()return b7>bb and(bb/b7)*self or self:H()end
function vector:bc(bb)self:K(self:ba(bb))end
function vector:bd(be,bf)bf=bf or be
return vector(mid(-be,self.a3,be),mid(-bf,self.a4,bf))end
function vector:bg(be,bf)self:K(self:bd(be,bf))end
function vector:bh()return vector(-self.a3,self.a4)end
function vector:bi()self.a3=-self.a3 end
function vector:bj()return vector(self.a3,-self.a4)end
function vector:bk()self.a4=-self.a4 end
function vector:bl(b6)local bm=sin(b6)local bn=cos(b6)return vector(bn*self.a3-bm*self.a4,bm*self.a3+bn*self.a4)end
function vector:bo()return vector(-self.a4,self.a3)end
function vector:bp()self:K(self:bo())end
function vector:bq()return vector(self.a4,-self.a3)end
function vector:br()self:K(self:bq())end end
package._c["engine/debug/codetuner"]=function()local bs={}function tuned(bt,bu)return bu end
return bs end
package._c["engine/debug/logging"]=function()local bv={ax={bw=1,bx=2,by=3,bz=4}}local bA=new_struct()bv.bA=bA
function bA:D(ax,bB,aZ)self.ax=ax
self.bB=bB
self.aZ=aZ end
function bA:_tostring()return"log_msg("..(joinstr(", ",self.ax,dump(self.bB),dump(self.aZ))..")")end
function bv.bC(bD)if bD.ax==bv.ax.bx then prefix="warning: "elseif bD.ax==bv.ax.by then prefix="error: "else prefix=""end
return"["..(bD.bB..("] "..(prefix..bD.aZ)))end
local bE=singleton(function(self)self.bF=true end)bv.bE=bE
function bE:log(bD)if self.bF then self:bG(bD)end end
console_log_stream=derived_singleton(bE)bv.console_log_stream=console_log_stream
function console_log_stream:bG(bD)printh(bv.bC(bD))end
file_log_stream=derived_singleton(bE,function(self)self.bH="game"end)bv.file_log_stream=file_log_stream
function file_log_stream:bI()printh("",self.bH.."_log",true)end
function file_log_stream:bG(bD)printh(bv.bC(bD),self.bH.."_log")end
local bJ=singleton(function(self)self.bK={['default']=true}self.bL=bv.ax.bw
self.bM={}end)bv.bJ=bJ
function bJ:bN()clear_table(self.bK)end
function bJ:bO(bP)if contains(self.bM,bP)then warn("logger:register_stream: passed stream already registered, ignoring it",'log')return end
add(self.bM,bP)end
function bJ:_generic_log(ax,bB,bQ)bB=bB or'default'if bJ.bK[bB]and bJ.bL<=ax then local bD=bA(ax,bB,stringify(bQ))for bP in all(self.bM)do bP:log(bD)end end end
function log(bQ,bB)bJ:_generic_log(bv.ax.bw,bB,bQ)end
function warn(bQ,bB)bJ:_generic_log(bv.ax.bx,bB,bQ)end
function err(bQ,bB)bJ:_generic_log(bv.ax.by,bB,bQ)end
return bv end
package._c["application/picosonic_app_ingame"]=function()local bR=require("application/picosonic_app_base")local bS=require("ingame/stage_state")local bT=derived_class(bR)function bT:bU()return{bS()}end
return bT end
package._c["application/picosonic_app_base"]=function()local bV=require("engine/application/gameapp")local bW=require("engine/input/input")local bv=require("engine/debug/logging")local bX=require("resources/visual")local bR=derived_class(bV)function bR:D()bV.D(self,fps60)end
function bR:bY()end
function bR:bZ()end
function bR:b_()end
return bR end
package._c["engine/application/gameapp"]=function()local c0=require("engine/application/flow")local c1=require("engine/application/coroutine_runner")local bW=require("engine/input/input")local bV=new_class()function bV:D(c2)self.c3={}self.c1=c1()self.c2=c2
self.c4=1/c2
self.c5=nil end
function bV:c6()return{}end
function bV:c7(c3)for c8 in all(c3)do c8.c9=self
self.c3[c8.type]=c8 end end
function bV:ca()self:c7(self:c6())end
function bV:bU()return{}end
function bV:cb(cc)for au in all(cc)do au.c9=self
c0:cd(au)end end
function bV:ce()self:cb(self:bU())end
function bV:cf()self:cg()self:ca()self:ce()c0:ch(self.c5)for ci,c8 in pairs(self.c3)do c8:cf()end
self:cj()end
function bV:cg()end
function bV:cj()end
function bV:ck()bW:cl()self.c1:cm()for ci,c8 in pairs(self.c3)do if c8.bF then c8:ck()end end
c0:ck()self:bZ()end
function bV:bZ()end
function bV:cn()cls()c0:co()for ci,c8 in pairs(self.c3)do if c8.bF then c8:co()end end
c0:cp()self:b_()end
function bV:b_()end
function bV:cq(cr,...)self.c1:cq(cr,...)end
function bV:cs()self.c1:cs()end
function bV:ct(cu)yield_delay(ceil(cu*self.c2))end
function bV:cv(cu,cw,...)self:cq(function(cu,...)self:ct(cu)cw(...)end,cu,...)end
return bV end
package._c["engine/application/flow"]=function()local bv=require("engine/debug/logging")local c0=singleton(function(self)self.cc={}self.cx=nil
self.cy=nil end)function c0:ck()self:cz()if self.cx then self.cx:ck()end end
function c0:co()if self.cx then self.cx:co()end end
function c0:cp()if self.cx then self.cx:cp()end end
function c0:cd(cA)self.cc[cA.type]=cA end
function c0:ch(cB)self.cy=self.cc[cB]end
function c0:cz(cB)if self.cy then self:cC(self.cy)end end
function c0:cC(cD)if self.cx then self.cx:cE()end
self.cx=cD
cD:cF()self.cy=nil
log("changed gamestate to "..cD.type,"flow")end
return c0 end
package._c["engine/application/coroutine_runner"]=function()require("engine/core/coroutine")local cG=require("engine/debug/logging")local c1=new_class()function c1:D()self.cH={}end
function c1:cq(cr,...)coroutine=cocreate(cr)add(self.cH,coroutine_curry(coroutine,...))end
function c1:cm()local cI={}for X,coroutine_curry in pairs(self.cH)do local cJ=costatus(coroutine_curry.coroutine)if cJ=="suspended"then local cK,by=coresume(coroutine_curry.coroutine,unpack(coroutine_curry.aN))elseif cJ=="dead"then add(cI,coroutine_curry)else warn("coroutine_runner:update_coroutines: coroutine should not be running outside its body: "..coroutine_curry,"flow")end end
for coroutine_curry in all(cI)do del(self.cH,coroutine_curry)end end
function c1:cs()clear_table(self.cH)end
return c1 end
package._c["engine/core/coroutine"]=function()coroutine_curry=new_class()function coroutine_curry:D(coroutine,...)self.coroutine=coroutine
self.aN={...}end
function coroutine_curry:_tostring()return"[coroutine_curry] ("..(costatus(self.coroutine)..(") ("..(joinstr_table(", ",self.aN,dump)..")")))end end
package._c["engine/input/input"]=function()button_ids={aj=0,al=1,ak=2,am=3,cL=4,a3=5}btn_states={cM=0,cN=1,cO=2,cP=3}input_modes={cQ=0,cR=1}local bW=singleton(function(self)self.cS=input_modes.cQ
self.cT=false
self.cU={}for X=0,1 do local t={}for X=0,5 do t[X]=false end
self.cU[X]=t end
self.cV={}for X=0,1 do local t={}for X=0,5 do t[X]=btn_states.cM end
self.cV[X]=t end end)local cW=0x5f2d
local cX=32
local cY=33
function bW:cZ(c_,d0)d0=d0 or 0
return self.cV[d0][c_]end
function bW:d1(c_,d0)local d2=self:cZ(c_,d0)return d2==btn_states.cM or d2==btn_states.cP end
function bW:d3(c_,d0)return not self:d1(c_,d0)end
function bW:d4(c_,d0)local d2=self:cZ(c_,d0)return d2==btn_states.cP end
function bW:d5(c_,d0)local d2=self:cZ(c_,d0)return d2==btn_states.cN end
function bW:cl()for d0=0,1 do self:d6(d0)end end
function bW:d6(d0)local d7=self.cV[d0]for c_,ci in pairs(d7)do if self.cS==input_modes.cQ then end
d7[c_]=self:d8(d7[c_],self:d9(c_,d0))end end
function bW:d9(c_,d0)if self.cS==input_modes.cQ then return btn(c_,d0)else d0=d0 or 0
return self.cU[d0][c_]end end
function bW:d8(da,d3)if da==btn_states.cM then if d3 then return btn_states.cN end elseif da==btn_states.cN then if d3 then return btn_states.cO else return btn_states.cP end elseif da==btn_states.cO then if not d3 then return btn_states.cP end else if d3 then return btn_states.cN else return btn_states.cM end end
return da end
return bW end
package._c["resources/visual"]=function()local db=require("engine/render/sprite_data")local bX={dc=74,dd=106,de=90,df={{colors.j,colors.d},{colors.q,colors.k},{colors.p,colors.d},{colors.o,colors.g},{colors.n,colors.c},{colors.m,colors.e},{colors.l,colors.k},{colors.k,colors.f}}}local dg={dh=db(sprite_id_location(1,0),nil,nil,colors.p),di=db(sprite_id_location(10,7),tile_vector(2,1),vector(4,4),colors.p)}bX.dg=dg
return bX end
package._c["engine/render/sprite_data"]=function()require("engine/render/sprite")local db=new_struct()function db:D(dj,dk,dl,dm)self.dj=dj
self.dk=dk or tile_vector(1,1)self.dl=dl or vector.ah()self.dm=dm or colors.b end
function db:_tostring()return"sprite_data("..(joinstr(", ",self.dj,self.dk,self.dl,self.dm)..")")end
function db:co(dn,dp,dq,b6)local dl=self.dl:H()if dp then local dr=self.dk.X*tile_size
dl.a3=dr-dl.a3 end
if dq then local ds=self.dk.Y*tile_size
dl.a4=ds-dl.a4 end
if not b6 or b6%1==0 then set_unique_transparency(self.dm)local dt=dn-dl
spr(self.dj:_(),dt.a3,dt.a4,self.dk.X,self.dk.Y,dp,dq)palt()else spr_r(self.dj.X,self.dj.Y,dn.a3,dn.a4,self.dk.X,self.dk.Y,dp,dq,dl.a3,dl.a4,b6,self.dm)end end
return db end
package._c["engine/render/sprite"]=function()function spr_r(X,Y,a3,a4,aR,du,dp,dq,dv,dw,b6,dm)local dx=tile_size*X
local dy=tile_size*Y
local dz=tile_size*aR
local dA=tile_size*du
local bm=sin(b6)local bn=cos(b6)local dB=max(dv,(dz-dv))-0.5
local dC=max(dw,(dA-dw))-0.5
local dD=dB*dB+dC*dC
local dE=ceil(sqrt(dD))-0.5
for dF=-dE,dE do for dG=-dE,dE do if dF*dF+dG*dG<=dD then local dH=dp and-1 or 1
local dI=dq and-1 or 1
local dJ=dv+dH*(bn*dF+bm*dG)local dK=dw+dI*(-bm*dF+bn*dG)if((dJ>=0 and dJ<dz)and dK>=0)and dK<dA then local aL=sget(dx+dJ,dy+dK)if aL~=dm then pset(a3+dF,a4+dG,aL)end end end end end end end
package._c["ingame/stage_state"]=function()require("engine/core/coroutine")local c0=require("engine/application/flow")local cA=require("engine/application/gamestate")local dL=require("engine/ui/overlay")local di=require("ingame/emerald")local dM=require("ingame/playercharacter")local dN=require("data/stage_data")local dO=require("resources/audio")local bX=require("resources/visual")local bS=derived_class(cA)local dP=rectfill
bS.type=':stage'bS.dQ={dR="play",cK="result"}function bS:D()cA.D(self)self.dS=1
self.dT=dN.dU[self.dS]self.dV=bS.dQ.dR
self.dM=nil
self.dW=false
self.dX={}self.dY=vector.ah()self.dZ=dL(0)end
function bS:cF()self.dV=bS.dQ.dR
self:d_()self.dW=false
self.dY=vector.ah()self.c9:cq(self.e0,self)self:e1()self:e2()self:e3()self:e4()end
function bS:cE()self.c9:cs()self.dM=nil
self.dZ:e5()camera()self:e6()end
function bS:ck()if self.dV==bS.dQ.dR then self.dM:ck()self:e7()self:e8()self:e4()else end end
function bS:co()camera()self:e9()self:ea()self:eb()end
function bS:ec(ed,ee,ef)for eg in all(ee)do if(ef==nil or ef(ed,eg))and eg:contains(ed)then return true end end
return false end
function bS:eh(ed)return self:ec(ed,self.dT.ei,function(ed,eg)return ed~=location(eg.aj,eg.ej)end)end
function bS:ek(ed)return self:ec(ed,self.dT.el,function(ed,eg)return ed~=location(eg.al,eg.ej)end)end
function bS:em(ed)for eg in all(self.dT.ei)do if ed==location(eg.aj,eg.ej)then return true end end end
function bS:en(ed)for eg in all(self.dT.el)do if ed==location(eg.al,eg.ej)then return true end end end
function bS:d_()local eo=self.dT.ep:a2()self.dM=dM()self.dM:eq(eo)end
function bS:e3()local er=bX.dg.di.dj:_()for X=0,127 do for Y=0,127 do local es=mget(X,Y)if es==er then mset(X,Y,0)add(self.dX,di(#self.dX+1,location(X,Y)))end end end end
function bS:e4()local et
if self.dM.dn.a4<tile_size*32 then et=vector(0,0)else et=vector(0,1)end
if self.eu~=et then local ev="data_stage"..(self.dS..("_"..(et.a3 ..(et.a4 ..".p8"))))log("reload "..ev,"reload")reload(0x2000,0x2000,0x1000,ev)self.eu=et end end
function bS:ew(ex)self.c9:cq(self.ey,self,ex)end
function bS:ey(ex)mset(ex.X,ex.Y,bX.dd)mset(ex.X+1,ex.Y,bX.dd+1)mset(ex.X,ex.Y-1,bX.de)mset(ex.X+1,ex.Y-1,bX.de+1)self.c9:ct(dN.ez)mset(ex.X,ex.Y,bX.dc)mset(ex.X+1,ex.Y,bX.dc+1)mset(ex.X,ex.Y-1,0)mset(ex.X+1,ex.Y-1,0)end
function bS:eA(dn)for eB in all(self.dX)do local eC=dn-eB:eD()local eE=max(abs(eC.a3),abs(eC.a4))if eE<dN.eF then return eB end end end
function bS:eG(eB)del(self.dX,eB)end
function bS:eH(dn,eI)if eI==1 then for eg in all(self.dT.ei)do if((tile_size*eg.al+3<=dn.a3 and dn.a3<=(tile_size+1)*eg.al+11)and tile_size*eg.ej-16<=dn.a4)and dn.a4<=(tile_size+1)*eg.eJ+16 then return 2 end end else for eg in all(self.dT.el)do if((tile_size*eg.aj-11<=dn.a3 and dn.a3<=tile_size*eg.aj-3)and tile_size*eg.ej-16<=dn.a4)and dn.a4<=(tile_size+1)*eg.eJ+16 then return 1 end end end end
function bS:e7()if not self.dW and self.dM.dn.a3>=self.dT.eK then self.dW=true
self.c9:cq(self.eL,self)end end
function bS:eL()self:eM()self.dV=bS.dQ.cK
self:e6(dN.eN)self.c9:ct(dN.eO)self:eP()end
function bS:eM()sfx(dO.eQ.eR)end
function bS:eP()load('picosonic_titlemenu.p8')end
function bS:e8()self.dY.a3=mid(screen_width/2,self.dM.dn.a3,self.dT.eS*tile_size-screen_width/2)self.dY.a4=mid(screen_height/2,self.dM.dn.a4,self.dT.eT*tile_size-screen_height/2)end
function bS:eU()camera(self.dY.a3-screen_width/2,self.dY.a4-screen_height/2)end
function bS:e0()self.dZ:eV("title",self.dT.eW,vector(50,30),colors.i)self.c9:ct(dN.eX)self.dZ:eY("title")end
local function eZ(a4,aL)line(0,a4,127,a4,aL)end
function bS:e9()camera()dP(0,0,127,127,colors.c)local e_=90-0.5*self.dY.a4
eZ(e_-1,colors.n)eZ(e_,colors.i)eZ(e_+1,colors.o)local f0={{0,60,140,220},{30,150,240},{10,90,210},{50,130}}local f1={{0,0,-1,0},{0,-1,-1,0},{0,-1,1,0},{0,1,-1,1}}for Y=0,3 do for f2 in all(f0[Y+1])do self:f3(f2,(e_-8.9)-14.7*Y,f1[Y+1],2+0.9*Y,3+3.5*Y)end end
local f4={4,3,6,2,1,5}local f5={0.7,1.5,1.2,1.7,1.1}local f6=0.015
for X=0,21 do local dG=f4[X%6+1]local a4=(e_+2)+dG
local f7=(f6*min(6,dG))/6
local f8=flr(f7*self.dY.a3)self:f9(f8,6*X,a4,f5[X%5+1])end
dP(0,e_+50,127,(e_+50)+screen_height,colors.e)local fa=0.3
local fb=0.42
local fc=fb-fa
local fd=0.36
local fe=fb-fd
for Y=0,1 do local f7=fd+fe*Y
local f8=flr(f7*self.dY.a3)self:ff(f8,(e_+33)+18*(1-Y),21,self.fg[Y+1],Y%2==0 and colors.m or colors.e)end
for Y=0,3 do local f7=fa+(fc*Y)/3
local f8=flr(f7*self.dY.a3)self:fh(f8,(e_+29)+8*Y,10,self.fi[Y+1],Y%2==0 and colors.m or colors.e)end end
function bS:f3(a3,a4,fj,fk,fl)local fm=t()*fl
x0=((a3-fm)+100)%300-100
local fn={0,1.5,3,4.5}local fo={0.8,1.4,1.1,0.7}for X=1,4 do circfill(x0+flr(fn[X]*fk),a4+fj[X],fo[X]*fk+1,colors.o)end
for X=1,4 do circfill(x0+flr(fn[X]*fk),a4+fj[X],fo[X]*fk,colors.i)end end
function bS:f9(f8,a3,a4,fp)local fq=(t()%fp)/fp
local fr,fs
if fq<0.2 then fr=colors.c
fs=colors.n elseif fq<0.4 then fr=colors.i
fs=colors.n elseif fq<0.6 then fr=colors.n
fs=colors.c elseif fq<0.8 then fr=colors.n
fs=colors.i else fr=colors.c
fs=colors.n end
pset((a3-f8)%screen_width,a4,fr)pset(((a3-f8)+1)%screen_width,a4,fs)end
function bS:e2()self.fi={}for Y=1,4 do self.fi[Y]={}local fp=20+10*(Y-1)for X=1,64 do self.fi[Y][X]=flr(3*abs(sin(X/fp))+rnd(8))end end
self.fg={}for Y=1,2 do self.fg[Y]={}local fp=70+35*(Y-1)for X=1,64 do self.fg[Y][X]=flr(9*abs(sin(X/fp))+rnd(4))end end end
function bS:fh(f8,a4,ft,fu,fv)local fw=#fu
for a3=0,127 do local eT=ft+fu[((a3+f8)%fw+1)]line(a3,a4,a3,a4-eT,fv)end end
function bS:ff(f8,a4,ft,fu,fv)local fw=#fu
for a3=0,127 do local eT=ft+fu[((a3+f8)%fw+1)]line(a3,a4,a3,a4+eT,fv)end end
function bS:ea()self:eU()self:fx()self:fy()self:fz()self:fA()end
function bS:fB(fC)local fD=self.dY-vector(screen_width/2,screen_height/2)local fE=self.dY+vector(screen_width/2,screen_height/2)local fF=max(0,flr(fD.a3/tile_size))local fG=min(flr((fE.a3-1)/tile_size),127)local fH=max(0,flr(fD.a4/tile_size))local fI=min(flr((fE.a4-1)/tile_size),32)for X=fF,fG do for Y=fH,fI do local fJ=mget(X,Y)if fJ~=0 and(fC==nil or fC(X,Y))then spr(fJ,tile_size*X,tile_size*Y)end end end end
function bS:fx()set_unique_transparency(colors.p)self:fB(function(X,Y)local fJ=mget(X,Y)return fget(fJ,sprite_flags.fK)and not self:eh(location(X,Y))end)dP(self.dT.eK,0,self.dT.eK+5,15*8,colors.l)end
function bS:fA()set_unique_transparency(colors.p)self:fB(function(X,Y)local fJ=mget(X,Y)return fget(fJ,sprite_flags.fL)or fget(fJ,sprite_flags.fK)and self:eh(location(X,Y))end)end
function bS:fz()self.dM:co()end
function bS:fy()for eB in all(self.dX)do eB:co()end end
function bS:eb()camera(0,0)self.dZ:fM()end
function bS:e1()music(self.dT.fN,0,(shl(1,0)+shl(1,2))+shl(1,3))end
function bS:e6(fO)if fO then fade_duration_ms=1000*fO else fade_duration_ms=0 end
music(-1,fade_duration_ms)end
return bS end
package._c["engine/application/gamestate"]=function()local cA=new_class()cA.type=':undefined'function cA:D()self.c9=nil end
function cA:cF()end
function cA:cE()end
function cA:ck()end
function cA:co()end
function cA:cp()end
return cA end
package._c["engine/ui/overlay"]=function()local fP=require("engine/ui/label")local dL=new_class()function dL:D(fQ)self.fQ=fQ
self.fR={}end
function dL:_tostring()return"overlay(layer: "..(self.fQ..")")end
function dL:eV(bt,aZ,dn,r)if not r then r=colors.b
warn("overlay:add_label no colour passed, will default to black (0)",'ui')end
if self.fR[bt]==nil then self.fR[bt]=fP(aZ,dn,r)else local fP=self.fR[bt]fP.aZ=aZ
fP.dn=dn
fP.r=r end end
function dL:eY(bt,aZ,dn)if self.fR[bt]~=nil then self.fR[bt]=nil else warn("overlay:remove_label: could not find label with name: '"..(bt.."'"),'ui')end end
function dL:e5()clear_table(self.fR)end
function dL:fM()for ci,fP in pairs(self.fR)do fP:cn()end end
return dL end
package._c["engine/ui/label"]=function()local fP=new_struct()function fP:D(aZ,dn,r)self.aZ=aZ
self.dn=dn
self.r=r end
function fP:_tostring()return"label('"..(self.aZ..("' @ "..(self.dn..(" in "..(color_tostring(self.r)..")")))))end
function fP:cn()api.print(self.aZ,self.dn.a3,self.dn.a4,self.r)end
return fP end
package._c["ingame/emerald"]=function()local bX=require("resources/visual")local di=new_class()di.di=di
function di:D(ad,location)self.ad=ad
self.location=location end
function di:_tostring()return"emerald("..(joinstr(', ',self.ad,self.location)..")")end
function di:eD()return self.location:a2()end
function di:co()local fS=bX.df[self.ad]pal(colors.j,fS[1])pal(colors.d,fS[2])bX.dg.di:co(self:eD())pal()end
return di end
package._c["ingame/playercharacter"]=function()local cG=require("engine/debug/logging")local c0=require("engine/application/flow")local bW=require("engine/input/input")local fT=require("engine/render/animated_sprite")local fU=require("data/collision_data")local fV=require("data/playercharacter_data")local fW=require("platformer/motion")local fX=require("platformer/world")local dO=require("resources/audio")local bX=require("resources/visual")control_modes={fY=1,fZ=2,f_=3}motion_modes={g0=1,g1=2}motion_states={g2=1,g3=2,g4=3}local dM=new_class()function dM:D()self.g5=fV.g6
self.g7=fV.g7
self.g8=fV.g8
self.g9=fV.g9
self.ga=fT(fV.gb)self:gc()end
function dM:gc()self.gd=control_modes.fY
self.ge=motion_modes.g0
self.gf=motion_states.g2
self.gg=directions.am
self.gh=horizontal_dirs.al
self.gi=1
self.gj=location(-1,-1)self.dn=vector(-1,-1)self.gk=0.
self.gl=0.
self.gm=vector.ah()self.gn=vector.ah()self.go=0.
self.gp=0.
self.gq=vector.ah()self.gr=false
self.gs=false
self.gt=false
self.gu=false
self.gv=false
self.ga:dR("idle")self.gw=0.
self.gx=0.
self.gy=false end
function dM:gz()return self.gf==motion_states.g2 end
function dM:gA()return self.gf==motion_states.g4 end
function dM:gB()return self:gA()and fV.gC or fV.gD end
function dM:gE()return self:gA()and fV.gF or fV.gG end
function dM:gH()return dir_vectors[rotate_dir_90_ccw(self.gg)]end
function dM:gI()return dir_vectors[self.gg]end
function dM:gJ(z)return z:bl(fX.gK(self.gg))end
function dM:eq(dn)self:gc()self:gL(dn)end
function dM:gM(gN)self:eq(gN-vector(0,self:gB()))end
function dM:gL(dn)self.dn=dn
self:gO()end
function dM:gP(gN)self:gL(gN-vector(0,self:gB()))end
function dM:gQ(ed)if self.gj~=ed then self.gj=ed
local bS=c0.cx
if bS:em(ed)then log("internal trigger detected, set active loop layer: 1",'loop')self.gi=1 elseif bS:en(ed)then log("internal trigger detected, set active loop layer: 2",'loop')self.gi=2 end end end
function dM:gR(b6,gS)self.go=b6
if gS then self.gx=0 elseif b6 then self.gx=b6 end
self.gg=fX.gT(b6)end
function dM:ck()self:gU()self:gV()self:gW()self.ga:ck()end
function dM:gU()if self.gd==control_modes.fY then local gX=vector.ah()if self.gf~=motion_states.g2 or self.gl<=0 then if bW:d3(button_ids.aj)then gX:a9(vector(-1,0))elseif bW:d3(button_ids.al)then gX:a9(vector(1,0))end end
if self.gl>0 then self.gl=self.gl-1 end
if bW:d3(button_ids.ak)then gX:a9(vector(0,-1))elseif bW:d3(button_ids.am)then gX:a9(vector(0,1))end
self.gq=gX
local gY=bW:d3(button_ids.cL)self.gr=gY and bW:d5(button_ids.cL)self.gs=gY
if bW:d5(button_ids.a3)then self:gZ()end end end
function dM:gZ()self:g_(self.ge%2+1)end
function dM:g_(h0)self.ge=h0
if h0==motion_modes.g0 then self:eq(self.dn)else self.gn=vector.ah()end end
function dM:gV()if self.ge==motion_modes.g1 then self:h1()return end
self:h2()end
function dM:h3(h4)local h5=1/0
local h6=nil
for X=1,2 do local h7=self:h8(h4,X)local h9=self:ha(h7)local hb=h9.hb
if hb<h5 or hb==h5 and self:hc()==X then h5=hb
h6=h9 end end
return fW.hd(h6.he,h5,h6.go)end
function dM:hc()if self:gz()then if self.gk~=0 then return signed_speed_to_dir(self.gk)end else if self.gm.a3~=0 then return signed_speed_to_dir(self.gm.a3)end end
return self.gh end
function dM:h8(h4,hf)local a3=h4.a3
local a4=h4.a4
if self.gg%2==1 then a3=flr(a3)else a4=flr(a4)end
local hg=vector(a3,a4)+self:gB()*self:gI()local hh=self:gJ(vector(horizontal_dir_signs[hf]*fV.hi,0))hh=vector(flr(hh.a3),flr(hh.a4))return hg+hh end
local function hj(hk,hl,hm,hn,ho,hp,hq,hr,hs)local ht=dir_vectors[hl]local h7=ho+hp*ht
local hu=vector.ai(h7+hm*ht)local hv=vector.ai(h7+hn*ht)local hw=hu:Z()local hx=tile_vector(ht.a3,ht.a4)local hy=fX.hz(h7-hw,hl)local hA=hu:H()while true do local hB,go
local hC=false
local bS=c0.cx
if hk.gi==1 and bS:ek(hA)or hk.gi==2 and bS:eh(hA)then hC=true end
if hC then hB,go=0 else local hD=hs and hu==hA
hB,go=fX.hE(hA,hy,hl,hD)end
if hB>0 then local hF=fX.hG(hA,hl)local hH=fX.hI(hF,fX.hJ(h7,hl),hl)-hB
local cK=hq(hA,hH,go)if cK then return cK end end
if hA==hv then return hr()end
hA=hA+hx end end
local function hK(he,hL,go)if hL<-fV.hM then return fW.hd(nil,-fV.hM-1,0)elseif hL<=fV.hN then return fW.hd(he,hL,go)end end
local function hO()return fW.hd(nil,fV.hN+1,nil)end
function dM:ha(h7)return hj(self,self.gg,-(fV.hM+1),fV.hN,h7,0,hK,hO)end
function dM:gO()local h9=self:h3(self.dn)local hL,hP=h9.hb,h9.go
if hL<=0 then if-hL<=fV.hM then self.dn.a4=self.dn.a4+hL
self:gQ(h9.he)self:gR(hP)else self.gj=nil
self:gR(0)end
self:hQ(motion_states.g2)else self:hQ(motion_states.g3)end end
function dM:hQ(hR)local hS=self:gA()self.gf=hR
if hS~=self:gA()then local hT=self:gJ(vector(0,fV.gD-fV.gC))local hU=hS and-1 or 1
self.dn:a9(hU*hT)end
if hR==motion_states.g3 then self.gj=nil
self:gR(nil)self.gk=0
self.gt=false elseif hR==motion_states.g4 then self.gj=nil
self:gR(nil,true)self.gk=0
self.gt=false
self.gy=false elseif hR==motion_states.g2 then self.gk=self.gm:af(vector.b5(self.go))self:hV()self.gu=false
self.gv=false
self.gy=false end end
function dM:h2()if self.gf==motion_states.g2 then self:hW()end
if self:gz()then self:hX()else self:hY()end
self:hZ()self:h_()self:eH()end
function dM:hX()self:i0()local i1=self:i2()if i1.i3 then self.gk=0 end
if flr(i1.dn.a3)<fV.hi then i1.dn.a3=ceil(fV.hi)self.gk=max(-0.1,self.gk)end
if self.gk~=0 then self.gw=abs(self.gk)else self.gw=0 end
self.gm=self.gk*vector.b5(self.go)self.dn=i1.dn
local i4=i1.i5
if self.gg~=directions.am and abs(self.gk)<fV.i6 then if self.go>=0.25 and self.go<=0.75 then i4=true end
self.gl=fV.i7 end
if i4 then self:hQ(motion_states.g3)else self:gQ(i1.he)self:gR(i1.go)self:i8()end
log("self.position: "..self.dn,"trace")log("self.position.x (hex): "..tostr(self.dn.a3,true),"trace")log("self.position.y (hex): "..tostr(self.dn.a4,true),"trace")log("self.velocity: "..self.gm,"trace")log("self.velocity.x (hex): "..tostr(self.gm.a3,true),"trace")log("self.velocity.y (hex): "..tostr(self.gm.a4,true),"trace")log("self.ground_speed: "..self.gk,"trace")end
function dM:i0()self:i9()self:ia()self:hV()end
function dM:i9()local ib=false
if self.go~=0 then local ic=1
if(self.gk~=0 and abs(sin(self.go))>=sin(-fV.id))and sgn(self.gk)~=sgn(sin(self.go))then ib=true
local ie=fV.ig
local ih=1
self.gp=min(self.gp+delta_time60,ie)ic=self.gp/ie end
self.gk=self.gk+(ic*fV.ii)*sin(self.go)end
if not ib then self.gp=0 end end
function dM:ia()if self.gq.a3~=0 then if self.gk==0 or sgn(self.gk)==sgn(self.gq.a3)then self.gk=self.gk+self.gq.a3*fV.ij
self.gh=signed_speed_to_dir(self.gq.a3)else local ik=1
if abs(sin(self.go))>=sin(-fV.id)and sgn(self.gk)==sgn(sin(self.go))then ik=fV.il end
self.gk=self.gk+(self.gq.a3*ik)*fV.im
local io=self.gk~=0 and sgn(self.gk)==sgn(self.gq.a3)if io then if abs(self.gk)>fV.ij then self.gk=sgn(self.gk)*fV.ij end
self.gh=signed_speed_to_dir(self.gq.a3)end end elseif self.gk~=0 then if abs(sin(self.go))<=sin(-fV.id)or sgn(self.gk)~=sgn(sin(self.go))then self.gk=sgn(self.gk)*max(0,(abs(self.gk)-fV.ip))end end end
function dM:hV()if abs(self.gk)>fV.iq then self.gk=sgn(self.gk)*fV.iq end end
function dM:i2()if self.gk==0 then return fW.i1(self.gj,self.dn,self.go,false,false)end
local ir=flr(self.dn.a3)local is=flr(self.dn.a4)local it=fW.i1(self.gj,vector(ir,is),self.go,false,false)local gg=self.gg
local hf=signed_speed_to_dir(self.gk)local iu=fX.hz(self.dn,gg)local iv=self.gk*cos((self.go-fX.gK(gg)))local iw=iv*self:gH()local ix=fX.hz(iw,gg)local iy=dM.iz(iu,ix)local iA=0
while iA<iy and not it.i3 do self:iB(hf,it)iA=iA+1 end
if not it.i3 then local iC=iu+ix>fX.hz(it.dn,gg)if iC then local iD=false
if ix>0 then local iE=it:H()self:iB(hf,iE)if iE.i3 then it=iE
iD=true end end
if not iD then fX.iF(it.dn,iu+ix,gg)end end end
return it end
function dM.iz(iG,iH)return abs(flr((iG+iH))-flr(iG))end
function dM:iB(hf,iI)log("  _next_ground_step: "..joinstr(", ",hf,iI),"trace2")local iJ=self:gJ(horizontal_dir_vectors[hf])local iK=iI.dn+iJ
log("step_vec: "..iJ,"trace2")log("next_position_candidate: "..iK,"trace2")local h9=self:h3(iK)local hL=h9.hb
log("signed_distance_to_closest_ground: "..hL,"trace2")local iL=hL*self:gI()if hL<=0 then if-hL<=fV.hM then iK:a9(iL)iI.i5=false else iI.i3=true end elseif hL>0 then if hL<=fV.hN then iK:a9(iL)iI.i5=false else iI.i5=true end end
if not iI.i3 then iI.i3=self:iM(iK)if not iI.i3 then iI.dn=iK
if iI.i5 then iI.he=nil
iI.go=nil else iI.he=h9.he
iI.go=h9.go end end end end
function dM:iM(h4)for X in all({horizontal_dirs.aj,horizontal_dirs.al})do local h7=self:h8(h4,X)if self:iN(h7)then return true end end
return false end
local function iO(hA,iP)if iP<0 then return true else return false end end
local function iQ()return false end
function dM:iN(h7)local iR=self:gE()return hj(self,oppose_dir(self.gg),(fV.hM+1)-iR,0,h7,iR,iO,iQ,true)end
function dM:i8()if self.gr then self.gr=false
self.gt=true end end
function dM:hW()if self.gt then self.gt=false
local iS=fV.iT*vector.b5(self.go):bq()self.gm:a9(iS)self:hQ(motion_states.g4)self.gu=true
sfx(dO.eQ.iU)return true end
return false end
function dM:hY()if self.gu then self.gu=false else self.gm.a4=self.gm.a4+fV.iV end
if self.gf==motion_states.g4 then self:iW()end
if self.gq.a3~=0 then self.gm.a3=self.gm.a3+self.gq.a3*fV.iX
self.gh=signed_speed_to_dir(self.gq.a3)end
self:iY()if self.gm.a4>fV.iZ then self.gm.a4=fV.iZ end
local i_=self:j0()if i_.j1 then self.gm.a3=0 end
if i_.j2 then self.gm.a4=0 end
if flr(i_.dn.a3)<fV.hi then i_.dn.a3=ceil(fV.hi)self.gm.a3=max(0,self.gm.a3)end
self.dn=i_.dn
if i_.j3 then self:gQ(i_.he)self:gR(i_.go)self:hQ(motion_states.g2)end
log("self.position: "..self.dn,"trace")log("self.velocity: "..self.gm,"trace")end
function dM:iW()if not self.gv and not self.gs then self.gv=true
local j4=-fV.j5
if self.gm.a4<j4 then log("interrupt jump "..(self.gm.a4 ..(" -> "..j4)),"trace")self.gm.a4=j4 end end end
function dM:iY()local j6=self.gm
if(j6.a4<0 and j6.a4>-fV.j7)and abs(j6.a3)>=fV.j8 then j6.a3=j6.a3*fV.j9 end end
function dM:j0()if self.gm:a5()then return fW.i_(nil,self.dn,false,false,false,nil)end
local it=fW.i_(nil,vector(self.dn.a3,self.dn.a4),false,false,false,nil)self:ja(it,self.gm,"x")log("=> "..it,"trace2")self:ja(it,self.gm,"y")log("=> "..it,"trace2")return it end
function dM:ja(iI,gm,a7)log("_advance_in_air_along: "..joinstr(", ",iI,gm,a7),"trace2")if gm:a6(a7)==0 then return end
local iG=iI.dn:a6(a7)local jb=dM.iz(iG,gm:a6(a7))iI.dn:a8(a7,flr(iI.dn:a6(a7)))local ao
if a7=="x"then ao=directions.al else ao=directions.am end
if gm:a6(a7)<0 then ao=oppose_dir(ao)end
local jc=0
while jc<jb and not iI:jd(ao)do self:je(ao,iI)log("  => "..iI,"trace2")jc=jc+1 end
if not iI:jd(ao)then local iC=iG+gm:a6(a7)>iI.dn:a6(a7)if iC then local iD=false
if gm:a6(a7)>0 then local iE=iI:H()self:je(ao,iE)log("  => "..iI,"trace2")if iE:jd(ao)then iI:K(iE)iD=true end end
if not iD then iI.dn:a8(a7,iG+gm:a6(a7))log("  => (after adding remaining subpx) "..iI,"trace2")end end end end
function dM:je(ao,iI)log("  _next_air_step: "..joinstr(", ",ao,iI),"trace2")local iJ=dir_vectors[ao]local iK=iI.dn+iJ
log("direction: "..ao,"trace2")log("step_vec: "..iJ,"trace2")log("next_position_candidate: "..iK,"trace2")if ao~=directions.ak then local h9=self:h3(iK)local hL=h9.hb
log("signed_distance_to_closest_ground: "..hL,"trace2")if self.gm.a4>0 or abs(self.gm.a3)>abs(self.gm.a4)then if hL<0 then if-hL<=fV.hM then iK.a4=iK.a4+hL
iI.j3,iI.go=true,h9.go
iI.he=h9.he
log("is landing at adjusted y: "..(iK.a4 ..(", setting slope angle to "..h9.go)),"trace2")else iI.j1=true
log("is blocked by wall","trace2")end else iI.j3,iI.go=false
iI.he=nil end end end
if not iI.j1 and(self.gm.a4<0 or abs(self.gm.a3)>abs(self.gm.a4))then local jf=self:iM(iK)if jf then if ao==directions.ak then iI.j2=true
log("is blocked by ceiling","trace2")else iI.j1=true
log("is blocked by ceiling as wall","trace2")end end end
if not iI:jd(ao)then iI.dn=iK
log("not blocked, setting motion result position to next candidate: "..iK,"trace2")end end
function dM:hZ()if self.gj then local jg=mget(self.gj.X,self.gj.Y)if fget(jg,sprite_flags.jh)then log("character triggers spring",'spring')local ex=self.gj:H()if jg==bX.dc+1 then ex.X=ex.X-1 end
self:ji(ex)end end end
function dM:ji(ex)self.gm.a4=-fV.jj
self:hQ(motion_states.g3)self.gy=true
local bS=c0.cx
bS:ew(ex)end
function dM:h_()local bS=c0.cx
local eB=bS:eA(self.dn)if eB then bS:eG(eB)end end
function dM:eH()local bS=c0.cx
local jk=bS:eH(self.dn,self.gi)if jk then log("external trigger detected, set active loop layer: "..jk,'loop')self.gi=jk end end
function dM:h1()self:jl()self.dn=self.dn+self.gn end
function dM:jl()self:jm"x"self:jm"y"end
function dM:jm(a7)if self.gq:a6(a7)~=0 then local jn=mid(-1,self.gq:a6(a7),1)self.gn:a8(a7,self.gn:a6(a7)+self.g8*jn)self.gn:a8(a7,mid(-self.g7,self.gn:a6(a7),self.g7))else if self.gn:a6(a7)~=0 then self.gn:a8(a7,sgn(self.gn:a6(a7))*max((abs(self.gn:a6(a7))-self.g9),0))end end end
function dM:gW()self:jo()self:jp()end
function dM:jo()if self.gf==motion_states.g2 then if self.gk==0 then self.ga:dR("idle")else if self.gw<fV.jq then self.ga:dR("walk",false,max(fV.jr,self.gw))else self.ga:dR("run",false,self.gw)end end elseif self.gf==motion_states.g3 then if self.gy and self.gm.a4>0 then self.gy=false end
if self.gy then self.ga:dR("spring_jump")else if self.gw<fV.jq then self.ga:dR("walk",false,max(fV.jr,self.gw))else self.ga:dR("run",false,self.gw)end end else if self.gw<fV.js then self.ga:dR("spin_slow",false,max(fV.jt,self.gw))else self.ga:dR("spin_fast",false,self.gw)end end end
function dM:jp()local b6=self.gx
if self.gf==motion_states.g3 and b6~=0 then if b6<0.5 then self.gx=max(0,abs(b6)-fV.ju)else self.gx=min(1,(abs(b6)+fV.ju))%1 end end end
function dM:co()local dp=self.gh==horizontal_dirs.aj
local jv=flr((8*self.gx+0.5))/8
local jw=vector(flr(self.dn.a3),flr(self.dn.a4))self.ga:co(jw,dp,false,jv)end
return dM end
package._c["engine/render/animated_sprite"]=function()local fT=new_class()function fT:D(jx)self.jx=jx
self.jy=false
self.jz=0.
self.jA=nil
self.jB=1
self.jC=0 end
function fT:_tostring()local jD={}for jE,ci in orderedPairs(self.jx)do add(jD,jE.." = ...")end
return"animated_sprite("..(joinstr(", ",("{"..(joinstr_table(", ",jD).."}")),self.jy,self.jz,self.jA,self.jB,self.jC)..")")end
function fT:dR(jE,jF,fl)if jF==nil then jF=false end
fl=fl or 1.
self.jz=fl
if self.jA~=jE or jF then self.jy=true
self.jA=jE
self.jB=1
self.jC=0 end end
function fT:jG()self.jy=false
self.jA=nil
self.jB=1
self.jC=0 end
function fT:ck()if self.jy then local jH=self.jx[self.jA]self.jC=self.jC+self.jz
while self.jC>=jH.jI do if self.jB<#jH.jJ then self.jB=self.jB+1
self.jC=self.jC-jH.jI else if jH.jK==anim_loop_modes.jL then self.jy=false
self.jB=1
self.jC=0 elseif jH.jK==anim_loop_modes.jM then self.jy=false
self.jB=#jH.jJ
self.jC=0 elseif jH.jK==anim_loop_modes.bI then self.jy=false
self.jA=nil
self.jB=1
self.jC=0 else self.jB=1
self.jC=self.jC-jH.jI
break end end end end end
function fT:co(dn,dp,dq,b6)if self.jA then local jH=self.jx[self.jA]local jN=jH.jJ[self.jB]jN:co(dn,dp,dq,b6)end end
return fT end
package._c["data/collision_data"]=function()local jO=require("data/tile_collision_data")sprite_flags={jP=0,jQ=1,jR=2,jS=3,jT=4,jh=5,fK=6,fL=7}sprite_masks={jP=1,jQ=2,jR=4,jS=8,jT=16,jh=32,fK=64,fL=128}local jU=transform({[1]={8,2},[2]={8,0},[3]={8,2},[4]={8,0},[5]={8,2},[6]={8,0},[7]={8,2},[9]={8,-2},[8]={8,-2},[10]={8,-2},[11]={8,-2},[12]={8,-4},[13]={8,-4},[14]={8,4},[15]={8,4},[16]={8,8},[17]={8,5},[18]={8,3},[19]={8,-3},[20]={8,-5},[21]={8,-8},[38]={4,-8},[22]={3,-8},[39]={-3,-8},[23]={-4,-8},[32]={-8,8},[33]={-8,5},[34]={-8,3},[35]={-8,-3},[36]={-8,-5},[37]={-8,-8},[24]={-4,8},[40]={-3,8},[25]={3,8},[41]={4,8},[26]={8,0},[27]={8,0},[28]={8,0},[29]={8,0},[42]={8,-4},[43]={8,-4},[44]={8,0}},function(jV)return atan2(jV[1],jV[2])end)local jW={[1]=1,[2]=2,[3]=3,[4]=4,[5]=5,[6]=6,[7]=7,[9]=9,[8]=8,[10]=10,[11]=11,[12]=12,[13]=13,[14]=14,[15]=15,[16]=16,[17]=17,[18]=18,[19]=19,[20]=20,[21]=21,[38]=38,[22]=22,[39]=39,[23]=23,[32]=32,[33]=33,[34]=34,[35]=35,[36]=36,[37]=37,[24]=24,[40]=40,[25]=25,[41]=41,[26]=26,[27]=27,[28]=28,[29]=29,[42]=42,[43]=43,[44]=44,[30]=29,[31]=29,[47]=29,[48]=29,[64]=29,[80]=29,[83]=29,[84]=29,[124]=29,[125]=29,[49]=1,[50]=2,[51]=3,[52]=4,[53]=5,[54]=6,[55]=7,[56]=8,[57]=9,[58]=10,[59]=11,[60]=12,[61]=13,[62]=14,[63]=15,[65]=29,[66]=29,[67]=29,[68]=29,[69]=29,[70]=29,[71]=29,[72]=29,[73]=29,[85]=29,[86]=29,[87]=29,[88]=29,[89]=29,[94]=29,[95]=29,[110]=29,[111]=29,[74]=26,[75]=27,[106]=29,[107]=29,[92]=28,[93]=29,[108]=28,[109]=29,[96]=16,[97]=17,[98]=18,[99]=19,[100]=20,[101]=21,[118]=38,[102]=22,[119]=39,[103]=23,[112]=32,[113]=33,[114]=34,[115]=35,[116]=36,[117]=37,[104]=24,[120]=40,[105]=25,[121]=41}local jX={}for fJ,jY in pairs(jW)do jX[fJ]=jO.jZ(jY,jU[jY])end
return{j_=function(fJ)return jX[fJ]end}end
package._c["data/tile_collision_data"]=function()local k0={}local jO=new_struct()function jO:D(k1,k2,k3,go,k4,k5)self.k1=k1
self.k2=k2
self.k3=k3
self.go=go
self.k4=k4
self.k5=k5 end
function jO:k6(k7)return self.k2[k7+1]end
function jO:k8(k9)return self.k3[k9+1]end
local function ka(kb)for z in all(kb)do if z~=0 and z~=8 then return false end end
return true end
function jO:kc()return ka(self.k2)end
function jO:kd()return ka(self.k3)end
function jO.ke(go)local kf=go<0.25 or go>=0.75
local k4=kf and vertical_dirs.am or vertical_dirs.ak
local k5=go<0.5 and horizontal_dirs.al or horizontal_dirs.aj
return k4,k5 end
function jO.jZ(jY,go)local k4,k5=jO.ke(go)local k1=sprite_id_location.a0(jY)return jO(k1,jO.kg(k1,k4),jO.kh(k1,k5),go,k4,k5)end
local function ki(L,kj,kk)kk=kk or 1
return function(ci,kl)local km=kl+kk
if(kk>0 and km<=kj or kk<0 and km>=kj)or kk==0 then return km end end,nil,L-kk end
function jO.kn(ko,kp,dF,dG,k4,k5,kq)local kr=sget(ko+dF,kp+dG)if kr~=0 then return kq(dF,dG,k4,k5)end end
function jO.ks(dF,dG,k4,k5)if k4==vertical_dirs.am then return tile_size-dG else return dG+1 end end
function jO.kt(dF,dG,k4,k5)if k5==horizontal_dirs.al then return tile_size-dF else return dF+1 end end
function jO.kg(ku,k4)local kb={}local kv=ku:Z()local kw=k4==vertical_dirs.am and{ki(0,tile_size-1)}or{ki(tile_size-1,0,-1)}for dF=0,tile_size-1 do for dG in unpack(kw)do column_height=jO.kn(kv.a3,kv.a4,dF,dG,k4,nil,jO.ks)if column_height then break end end
if not column_height then column_height=0 end
add(kb,column_height)end
return kb end
function jO.kh(ku,k5)local kb={}local kv=ku:Z()local kx=k5==horizontal_dirs.al and{ki(0,tile_size-1)}or{ki(tile_size-1,0,-1)}for dG=0,tile_size-1 do for dF in unpack(kx)do row_width=jO.kn(kv.a3,kv.a4,dF,dG,nil,k5,jO.kt)if row_width then break end end
if not row_width then row_width=0 end
add(kb,row_width)end
return kb end
return jO end
package._c["data/playercharacter_data"]=function()local ky=require("engine/data/serialization")local db=require("engine/render/sprite_data")local kz=require("engine/render/animated_sprite_data")local kA={ij=0.0234375,im=0.25,il=0.5,ip=0.0234375,ii=0.0625,id=0.075,ig=0.5,iX=0.046875,j9=0.96875,j8=0.25,j7=8,iq=3,i6=1.25,i7=30,iZ=32,iT=3.25,j5=2,jj=5,iV=0.109375,hi=2.5,gD=8,gG=16,gC=4,gF=8,hM=4,hN=4,g7=6,g8=0.1,g9=1,ju=0.0095,kB=ky.kC([[{
      idle   = {{0,  8}, {2, 2}, {10, 8}, 14},
      walk1  = {{2,  8}, {2, 2}, {10, 8}, 14},
      walk2  = {{4,  8}, {2, 2}, { 9, 8}, 14},
      walk3  = {{6,  8}, {2, 2}, {10, 8}, 14},
      walk4  = {{8,  8}, {2, 2}, {10, 8}, 14},
      walk5  = {{10, 8}, {2, 2}, {10, 8}, 14},
      walk6  = {{12, 8}, {2, 2}, {10, 8}, 14},
      spring_jump = {{14, 8}, {2, 3}, {9, 8}, 14},
      run1   = {{0, 10}, {2, 2}, {10, 8}, 14},
      run2   = {{2, 10}, {2, 2}, {10, 8}, 14},
      run3   = {{4, 10}, {2, 2}, {10, 8}, 14},
      run4   = {{6, 10}, {2, 2}, {10, 8}, 14},
      spin_full_ball = {{0, 12}, {2, 2}, { 6, 6}, 14},
      spin1  = {{2, 12}, {2, 2}, { 6, 6}, 14},
      spin2  = {{4, 12}, {2, 2}, { 6, 6}, 14},
      spin3  = {{6, 12}, {2, 2}, { 6, 6}, 14},
      spin4  = {{8, 12}, {2, 2}, { 6, 6}, 14},
    }]],function(t)return db(sprite_id_location(t[1][1],t[1][2]),tile_vector(t[2][1],t[2][2]),vector(t[3][1],t[3][2]),t[4])end),jr=0.625,jt=0.625,jq=3,js=3}kA.gb=ky.kC([[{
    idle = {{"idle"},               10,                2},
    walk  = {{"walk1", "walk2", "walk3", "walk4", "walk5", "walk6"},
                                    10,                4},
    run  = {{"run1", "run2", "run3", "run4"},
                                     5,                4},
    spin_slow = {{"spin_full_ball", "spin1", "spin2", "spin3", "spin4"},
                                     5,                4},
    spin_fast = {{"spin_full_ball", "spin1", "spin2", "spin_full_ball", "spin3", "spin4"},
                                     5,                4},
    spring_jump = {{"spring_jump"}, 10,                2}
}]],function(t)return kz.kD(kA.kB,t[1],t[2],t[3])end)return kA end
package._c["engine/data/serialization"]=function()local ky={}local kE={' ','\n'}local kF={' ','\n',',','=',']','}'}function ky.kC(kG,kH)local kI,kJ=ky.kK(kG,1)if kH then kI=transform(kI,kH)end
return kI end
function ky.kK(kG,kL,kM)local cK,kJ
local kN=false
local kO=ky.kP(kG,kL)local kQ=sub(kG,kO,kO)if kQ=='{'then cK,kJ=ky.kR(kG,kO+1)elseif kQ=='"'or kQ=="'"then cK,kJ=ky.kS(kG,kO+1,kQ)else kJ=ky.kT(kG,kO)local kU=sub(kG,kO,kJ-1)if kU=='true'then cK=true elseif kU=='false'then cK=false elseif kU~='nil'then local kV=tonum(kU)if kV then cK=kV end
if not cK then if kM then cK=kU
kN=true end end end end
return cK,kJ,kN end
function ky.kW(kG,kL)local kN,kX,v,w=false,false
local kJ=ky.kP(kG,kL)local kQ=sub(kG,kJ,kJ)local kY,kZ
if kQ~='}'then kX=true
if kQ=='['then kY,kJ=ky.kK(kG,kJ+1)kJ=ky.kP(kG,kJ)local k_=sub(kG,kJ,kJ)kJ=kJ+1 else kY,kJ,kN=ky.kK(kG,kJ,true)end end
if kX then kJ=ky.kP(kG,kJ)local l0=sub(kG,kJ,kJ)if l0=='='then v=kY
kJ=ky.kP(kG,kJ+1)w,kJ=ky.kK(kG,kJ)kJ=ky.kP(kG,kJ)l0=sub(kG,kJ,kJ)else w=kY end
if l0==','then kJ=kJ+1 end end
return kX,v,w,kJ end
function ky.kR(kG,kL)local cK={}local l1,v,w,kX=1
while true do kX,v,w,kL=ky.kW(kG,kL)if not kX then break end
if v then cK[v]=w else cK[l1]=w
l1=l1+1 end end
return cK,kL+1 end
function ky.kS(kG,kL,l2)for X=kL,#kG do local aL=sub(kG,X,X)if aL==l2 then return sub(kG,kL,X-1),X+1 end end end
function ky.l3(kG,kL,l4,l5)for X=kL,#kG do local aL=sub(kG,X,X)local l6=contains(l4,aL)if not l5 and l6 or l5 and not l6 then return X end end end
function ky.kP(kG,kL)return ky.l3(kG,kL,kE,true)end
function ky.kT(kG,kL)local l7=ky.l3(kG,kL,kF)return l7 and l7 or#kG+1 end
return ky end
package._c["engine/render/animated_sprite_data"]=function()local kz=new_struct()anim_loop_modes={jL=1,jM=2,bI=3,l8=4}function kz:D(jJ,jI,jK)self.jJ=jJ
self.jI=jI
self.jK=jK end
function kz.l9(la)return kz({la},1,anim_loop_modes.jM)end
function kz.kD(lb,lc,jI,jK)local jJ={}for ld in all(lc)do add(jJ,lb[ld])end
return kz(jJ,jI,jK)end
function kz:_tostring()return"animated_sprite_data("..(joinstr(", ",("["..(#self.jJ.." sprites]")),self.jI,self.jK)..")")end
return kz end
package._c["platformer/motion"]=function()local fW={}local hd=new_struct()fW.hd=hd
function hd:D(he,hb,go)self.he=he
self.hb=hb
self.go=go end
function hd:_tostring()return"ground_query_info("..(joinstr(", ",self.he,self.hb,tostr(self.go))..")")end
local i1=new_struct()fW.i1=i1
function i1:D(he,dn,go,i3,i5)self.he=he
self.dn=dn
self.go=go
self.i3=i3
self.i5=i5 end
function i1:_tostring()return"ground_motion_result("..(joinstr(", ",self.he,self.dn,self.go,self.i3,self.i5)..")")end
local i_=new_struct()fW.i_=i_
function i_:D(he,dn,j1,j2,j3,go)self.he=he
self.dn=dn
self.j1=j1
self.j2=j2
self.j3=j3
self.go=go end
function i_:jd(ao)if ao==directions.aj or ao==directions.al then return self.j1 elseif ao==directions.ak then return self.j2 else return self.j3 end end
function i_:_tostring()return"air_motion_result("..(joinstr(", ",self.he,self.dn,self.j1,self.j2,self.j3,self.go)..")")end
return fW end
package._c["platformer/world"]=function()local jO=require("data/tile_collision_data")local fU=require("data/collision_data")local fX={}function fX.gT(b6)if(not b6 or b6>=0.875)or b6<=0.125 then return directions.am elseif b6<0.375 then return directions.al elseif b6<=0.625 then return directions.ak else return directions.aj end end
function fX.gK(gg)return(0.25*(3-gg))%4 end
function fX.hz(le,gg)return gg%2==0 and le.a4 or le.a3 end
function fX.hJ(le,gg)return gg%2==1 and le.a4 or le.a3 end
function fX.iF(le,w,gg)if gg%2==0 then le.a4=w else le.a3=w end end
function fX.hI(lf,lg,gg)if gg<2 then return lg-lf else return lf-lg end end
function fX.hG(ed,gg)return fX.hJ(ed:a2()+4*dir_vectors[gg],gg)end
function fX.lh(he)local li=mget(he.X,he.Y)return fU.j_(li)end
function fX.hE(he,hy,gg,hD)if((he.X>=0 and he.X<128)and he.Y>=0)and he.Y<32 then local lj=mget(he.X,he.Y)local lk=fget(lj,sprite_flags.jP)if lk then local ll=fU.j_(lj)if ll then local kc=ll:kc()local kd=ll:kd()local lm=kc or kd
if gg%2==1 then local eT=ll:k6(hy)if ll.k4==vertical_dirs.am and gg==directions.ak or ll.k4==vertical_dirs.ak and gg==directions.am then if hD and not kc then return 0 end
return eT>0 and tile_size or 0,fX.gK(gg)elseif lm then return eT,fX.gK(gg)end
return eT,ll.go else local eS=ll:k8(hy)if ll.k5==horizontal_dirs.al and gg==directions.aj or ll.k5==horizontal_dirs.aj and gg==directions.al then if hD and not kd then return 0 end
return eS>0 and tile_size or 0,fX.gK(gg)elseif lm then return eS,fX.gK(gg)end
return eS,ll.go end end end end
return 0 end
return fX end
package._c["resources/audio"]=function()local dO={}local eQ={eR=58,iU=59,ln=60,lo=61,lp=62}local lq={lr=0}dO.eQ=eQ
dO.lq=lq
return dO end
package._c["data/stage_data"]=function()local ls=require("engine/core/location_rect")local db=require("engine/render/sprite_data")local dO=require("resources/audio")return{eF=8,eX=4.0,eO=1.0,eN=1.0,ez=0.15,dU={[1]={eW="angel island",eS=128,eT=64,ep=location(3,24),eK=1024,fN=dO.lq.lr,el={ls(87,19,89,24),ls(115,8,118,14)},ei={ls(90,19,92,24),ls(120,8,123,14)}}}}end
package._c["engine/core/location_rect"]=function()local ls=new_struct()function ls:D(aj,ej,al,eJ)self.aj=aj
self.ej=ej
self.al=al
self.eJ=eJ end
function ls:_tostring()return"location_rect("..(joinstr(', ',self.aj,self.ej,self.al,self.eJ)..")")end
function ls:contains(ed)return((self.aj<=ed.X and ed.X<=self.al)and self.ej<=ed.Y)and ed.Y<=self.eJ end
return ls end
function require(lt)local lu=package.a
if lu[lt]==nil then lu[lt]=package._c[lt]()end
if lu[lt]==nil then lu[lt]=true end
return lu[lt]end
require("engine/pico8/api")require("engine/common")require("common")local bs=require("engine/debug/codetuner")local bv=require("engine/debug/logging")local bT=require("application/picosonic_app_ingame")local c9=bT()function _init()bv.bJ:bO(bv.console_log_stream)bv.bJ:bO(bv.file_log_stream)bv.file_log_stream.bH="picosonic_ingame"bv.file_log_stream:bI()bv.bJ.bK={['default']=true,['codetuner']=true,['flow']=true,['itest']=true,['log']=true,['ui']=true,['loop']=true,['reload']=true}c9.c5=':stage'c9:cf()end
function _update60()c9:ck()end
function _draw()c9:cn()end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000000000000000000000077
00700700777777777777777700000000000000000000000000000000000000000000000000000000000000007777777777770000000000000000000000007777
00077000777777777777777777770000000000000000000000000000000000000000000000000000000077777777777777777700000000000000000000777777
00077000777777777777777777777777777777770000000000000000000000000000000000000000777777777777777777777777000000000000000077777777
00700700777777777777777777777777777777777777000000000000000000000000000000007777777777777777777777777777770000000000007777777777
00000000777777777777777777777777777777777777777777777777000000000000000077777777777777777777777777777777777700000000777777777777
00000000777777777777777777777777777777777777777777777777777700000000777777777777777777777777777777777777777777000077777777777777
70000000700000000000000000000000000000070000000700000007777777777777777770000000000000000000000000007777777777774444444999494444
77000000770000000000000000000000000000770000007700000007077777777777777070000000000000000000000000007777777777774444494994444444
77700000777700000000000000000000000077770000077700000007077777777777777070000000000077777777777700007777777777774444494994444444
77770000777770000000000000000000000777770000777700000077007777777777770077000000000077777777777700007777777777774444444999494444
77777000777777700000000000000000077777770007777700000077000777777777700077000000000077777777777700007777777777774444444999444444
77777700777777777000000000000007777777770077777700000077000777777777700077000000000077777777777700007777777777774444949499944444
77777770777777777770000000000777777777770777777700000777000077777777000077700000000077777777777700007777777777774444949499494444
77777777777777777777700000077777777777777777777700000777000077777777000077700000000077777777777700007777777777774444949999494444
7777777777777777777770000007777777777777777777770000777700000777777000007777000000000000000000770000000000000000e30bbebe44444444
77777770777777777770000000000777777777770777777700007777000007777770000077770000000000000000777700000000000000003bebeeb349444444
7777770077777777700000000000000777777777007777770007777700000077770000007777700000000000007777770000000000000000beb33b3e44444494
7777700077777770000000000000000007777777000777770007777700000077770000007777700000000077777777770000000000000000eb3e33eb44494444
7777000077777000000000000000000000077777000077770077777700000077770000007777770000007777777777770000777700000000e03bb03b44494444
77700000777700000000000000000000000077770000077707777777000000077000000077777770007777777777777700007777000000003beb3ebe44444494
7700000077000000000000000000000000000077000000770777777700000007700000007777777077777777777777770000777700000000b3b33eb344944444
7000000070000000000000000000000000000007000000077777777700000007700000007777777777777777777777770000777700000000eebeebee44444444
44444444eaeaeeeeeeeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaebeeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44449444babaeabeeaeebeebeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeebaeabbbabbeeeeeeeeeeeeeeeeeeeeeeeeeaeab
44444494bbbababbbababbbbeebeeaeeeeeeeebeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeaeebbabab3babbbeaeeeeeeeeeeeeeeeeeeaeeebbab
44949444bbbbbbbbabbbbbbababbeaaeebeaeebeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeaaebbabbbbbbb3bbbbbbaeeeeeeeeeeeeeeeeeeaeabbbbb
44499444b3babbb3bbbbabbababbb3ababbababaeaeeeeaeeeeeaeeeeeeeeeeeeeeeeeeeeaeeeeaeba3bbbabbb3bab3bb3bababbeaeeeeeeeeeeeeaeabbab3bb
44949944b3bb3bb3bb3ba3bbb3bbb3b3b3bbbbbababaebaeeeaebeeaeeeeeeeeeeeeeeeeeabeababbb3bbbbbbb3bbbbbb3babbbbbaeaeeeeeeeeaeabbbbab3bb
44949944bbbb3bbbbb3bb3b3bbb3b3bbb3bb3bb3bbbabbabababbabbbaeeaeeeeeeaeeabbabbabbbbb3bbbbbbbbbbb3bb3bbb3bbbbbaeeaeeaeeabbbb3bbbb3b
44449444bb3bbbbb3bbbb3bbbbb3bbbbbbbb3bb3bb3abbbbbb3bbbbbbabaaeaeeaeaababbbbbabbbbbbb3b3bbbbbbbbbbbbbbbbb3ababbaeeabbaba3b3b3bb3b
44949444bbbbbbbbbbbbbbbbbbbb3bbbb3bbbbbbbbbbbb3bbbbbbb3bbababbabbabbababb3bbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeee
44999444bb0bb3b3bb3bb0bbbbb303bbb3b3bb3bb3bb3b3bb3b3bbbbb3bbbbabbabbbbbbbbbb3b3beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee575eeeee
449944443003b030b30b30033b300033bbbbbb3bb3bbbbbbbbb3bb3bb3bbbbbbbbbb3b3bb3bb3bbbeeee999aaa7777a9eeeeeeeeeeeeeeeeeeeeeeee5775eeee
49494944004030003003040003004000bbbb0bbbbbb0bbbb3bbbb33bbbbb3b3bbbbbbb3bb33bbbb3eeee444999aa7aa9eeeeeeeeeeeeeeeeeeeeeeee57775eee
44499444044400440000044440044440b03b03bbbb30b30b033b303bbbbbbb3bbb3bbbbbb303b330eeee44999aa777a9eeeeeeeeeeeeeeeeeeeeeeee577775ee
44999444444444444400449444444444000b00b03b00b00003033003bbbbbbbbbb3bbbbb30033030eeeeeeddddddddeeeeeeeeeeeeeaeeeeeeeeeaee57755eee
44994944444944444404449444494444040300300300304040003040b3b3bbbbbbbb3b3b30400000eeeeed66777766deeaeeeeaeeaeaeeaeeeaeaaee575eeeee
444949444444444444444444444944444440040000440444404004403bb3bb3bb3bb3bb304400404eeeeeeddddddddeeebeebeaebaebeebeeabeabebe5eeeeee
49499444eeeeeeebbeeeeeee4444444494444444bb3bbbb33bbbbbbb0b30b30bb3bb03b03bbbb3bbeeeeeeeeeeeeeeeeeeeeeeed71d7deee4444449999494444
44949444eeeeeeabbaeeeeee4449444494944444bbbb3b300bb3b3b30030b00bb03b030003b3bbbbeeeeeeeeeeeeeeeeeeeee1d7771dd1ee4444949999444444
49949944eeeeeeabbaeeeeee4444494444444444b3bb3b0403b333b040003003b003000440b3bb3beeeeeeeeeeeeeeeeeeeee11d7d0d111e4344999994494444
44949494eeeeeeb33beeeeee4444494994444444b33bbb0440303030440400403000404440bbb33beeeeeeeeeeeeeeeeeeeee177d100771e4b34394999494444
44999944eeeeeebeebeeeeee44444449949444443003b304400000004444444004044444403b3003eeee999aaa7777a9eeeed7777007777e3bb4b94999994444
49994934eeeeeebeebeeeeee44449499994444440403300444040404444494440444444440033040eeee444999aa7aa9eeeddd7710ddd711bbbb3999999944b3
b39933b3eeeeeeeeeeeeeeee44449499494944444440304444444444444494444449444444030444eeee44999aa777a9eeedddd110dddd11b33bb939993b43bb
bb93bbbbeeeeeeeeeeeeeeee44449449494944444444004444444444444444444444444444004444eeeeeeedd766deeeeeeddd11101d0110bb33b3b3393b3bbb
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee0eeeeeee404444444444444444eeeeeeeeeeeeed67dddeeeeeee1111171110000bb3b3bbbbb3bbb3b
40eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04eeeeeee4e04944444444944e4eeeeeeeeeeeed6ddeeeeeeeeee000ddd710770eb3bb33bbb333bb3b
444eeeee4440eeeeeeeeeeeeeeeeeeeeeeee0044eeeee444eeeeeee4e04944444944440e4eeeeeeeeeeeee55dddeeeeeeeee0dddd107777e03b3bbbbb3b3b3b0
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04444eeee0494eeeeee04ee044944449440ee40eeeeeeeeeeeee55ddddeeeeeee777111077777b03bbb333bbbbbb0
44440eee4944400eeeeeeeeeeeeeeeaee0444944eee04494eeeeee04eee0444444940eee40eeeeeeeeeeeeeeeedd6deeeeed7777100d7711b333bbbbb33b30bb
494944ee449444400eeeeeeeeeeeaea004444994ee449444eeeeee44eee0449444440eee40eeeeeeeeeeeeeeed77deeeeedddd7710dddd11b3bbb3bb30033bbb
4449440e44944944440eeeeeeeee303b44944494e0444494eeeee044eeee44944944eeee440eeeeeeeeeeeed77ddeeeeeeddddd110ddd1113bb330bbbb3b33bb
444444404444444444440eeeebebbb3b4444444404444444eeeee044eeee04444440eeee444eeeeeeeeeeed6ddeeeeeeeedddd11101d0110bbbbb0bbb33bb3bb
444444404444444444440eeeeee044444444444404444444eeee0444eeeee494440eeeee4440eeeeeee888eeeeeeeeee4444444444444444e3bbbbb3bbbb3bbe
4494440e44444444440eeeeeeeeee00494494444e0449494eeee4444eeeee044440eeeee4944eeeee7777788eeeeeeee0449444449444444eeba3b3e3bb3e3b3
449940ee499449400eeeeeeeeeeeeee044444944ee444494eee04494eeeeee4444eeeeee49440eee777777888eeeeeee0449494449444940e3b3e3ee3bb3eebb
44444eee4494440eeeeeeeeeeeeeeeeee0044994eee04444eee04494eeeeee0444eeeeee44440eee222888222eeeeeee4449494444444940ebb3eeeeeabbeea3
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04494eeee0494ee044444eeeeee0440eeeeee494440eee2288822eeeeeeee0444494444440944ebbeeeeee3b3ee3e
440eeeee4400eeeeeeeeeeeeeeeeeeeeeeee0444eeeee444e0444494eeeeeee44eeeeeee4449440eee28882eeeeeeeee0044444400000440eabbeeeeee3eeeee
44eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04e4449444eeeeeee44eeeeeee4949444eeee282eeeeeeeeee0000040000e00000ee3beeeeeeeeeeee
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee004444444eeeeeee44eeeeeee44444440eeee2eeeeeeeeeeee00000000ee00000eeebbeeeeeeeeeee
eeeeeeccceeeeeeeeeeeeeccceeeeeeeeeeeeccceeeeeeeeeeeeeeccceeeeeeeeeeeecccceeeeeeeeeeeecccceeeeeeeeeeeecccceeeeeeeeeeeeeecccceeeee
eeeeeccccceeceeeeeeeeccccceeceeeeeeeccccceeceeeeeeeeeccccceeceeeeeeecccccceceeeeeeeecccccceceeeeeeeecccccceceeeeeeeeeeeeccccceee
eeeeeecffcccceeeeeeeeecffcccceeeeeeeecffcccceeeeeeeeeecffcccceeeeeeeeeccfccceeeeeeeeeeccfccceeeeeeeeeeccfccceeeeeeeeeeeeccccccee
eeeeeccfcc7ccceeeeeeeccfcc7ccceeeeeeccfcc7ccceeeeeeeeccfcc7ccceeeeeeccccfc7cceeeeeeeccccfc7cceeeeeeeccccfc7cceeeee77eeccffccccce
eeeeccccc770cceeeeeeccccc770cceeeeeccccc770cceeeeeeeccccc770cceeeeeccccccc71ceeeeeeccccccc71ceeeeeeccccccc71ceeee7777cccfc7ccc77
eeecccccc770ceeeeeecccccc770ceeeeecccccc770ceeeeeeecccccc770ceeeeecccccccc70ceeeeecccccccc70ceeeeecccccccc70ceeeeee7ffccc707ccee
eeeeeeccff77f0eeeeeeeeccff77f0eeeeeeeccff77f0eeeeeeeeeccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeee7eecfccf07c67e
eeeeeccccfffeeeeeeeeeccccfffeeeeeeeeccccfffeeeeeeeeeeccccfffeeeeeeeecccc7fffeeeeeeeecccccff7eeeeeeeecccccfffeeeeeeeecccccffff0ee
eeeeccc99ccfeeeeeeeecffcff6eeeeeeeecffccfee56eeeeee777fccfeeeeeeeeeccc9777eeeeeeeeeccccffe777eeeeeeccccffee7eeeeeeeeeecf9effeeee
eeeeeeef77ff66eeeeeefeecffeeeeeee77feccff9966ee8ee7770ccff66eeeeeeeee9f07eeeeeeeee6ceccfff770eeeeeeceecffe777eeeeeeeeccffeeeeeee
eeeeeecc777f56eeeee770ccc7feeeee707ecccffeeeee88eee7ececff56eeeeeeeeecccf111eeeeee66ccccf1eeee20eee07ccccf770eeeeeeececcceeeeeee
eeeeeece0711eeeeeee777ec887eeeeee7eececcccc78780e002661cccee80eeeeeeececce61eeeeeeeececeee172700eee087eee1eeeeeeeeeeeeecceeeeeee
eeeeeeeeece1eeeeeeee7e260887eeeeee02611eeec7870e0262611ec78780eeeee87ccce0262eeeee86cceeee77200eeee088eeee16eeeeeeeeeee6ceeeeeee
eeeeeeeee7e7eeeeeeeee022000788eee02261eeeee8880e022eeeee78780eeeee088eeeee0222eee6886eeeeee200eeeeee078eee626220eeeeeee2ceeeeeee
eeeeeeeee878022eeeeee0022eee00ee062eeeeeeeee00eeeeeeeeee8870eeeeee0877eeeeee00eee860eeeeeee00eeeeeeee00eee02600eeeeeee06c7eeeeee
eeeeeeeee7888e22eeeeee00600eeeee22eeeeeeeeeeeeeeeeeeeeee000eeeeeeee08888eeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeee0277eeeeee
eeeeecccceeeeeeeeeeeeecccceeeeeeeeeeecccceeeeeeeeeeeeecccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0288eeeeee
eeeeeecffcceceeeeeeeecccccceceeeeeeeeecffcceceeeeeeeecccccceceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0870eeeee
eeeeeeecffccceeeeeeeeecffcccceeeeeeeeeecffccceeeeeeeeecffcccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee780eeeee
eeeeccccccc7cceeeeeeeccfccc7cceeeeeeccccccc7cceeeeeeeccfccc7cceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee080eeeee
eeeccccccc770ceeeeeecccccc770ceeeeeccccccc770ceeeeeecccccc770ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee
eeeeeccccc770ceeeeeccccccc770ceeeeeeeccccc770ceeeeeccccccc770ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeec9cc70cfffeeeeeee9c888cfffeeeeeec9cc702f2feeeeeee9cc70cfffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee9ff77756e2eeeeee9f888856eeeeeeee9ff77752e22eeeee9ff777e6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee7ecc77766220eeee228887766eeeeeeeee11777662222eee221177766eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e777cccff1e260eee22888cffeeeeee2ee87e11ffeee280ee228e11ffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
087cccece16220ee222ccee11eeee2e2088111ecccee780e22211eecceeeeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0888eeeee6820eee22eeeeee1eeee2220887eeeeeec7870e22eeeeeceeeee2e2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
08878eeee8880eee2eeee871eeee222e08822eeeee7880ee2eeeee77eeee2222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e07782eeee80eeeee2ee8877222222eee02222eeee8880eee2eee0887822222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0888222eeeeeeeeeee82227222eeeeee0222222ee80eeeeeeee08788822eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeccccceeeeeeeeeeecccceeeeeeeeeeeeccecceeeeeeeeeee2222eeeeeeeeeeeeeee8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eecccccccceeeeeeeeccccccceeeeeeeeeceeccecceeeeeeee278227cceeeeeeeeeeee0e82eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eccccccc7cceeeeeeccccfccceeeeeeeececccccccceeeeee28777ccceceeeeeeeecccfee82eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eccccc777cceeeeecccccfc7cceeeeeeecccccccccceeeeee8ee777fcceeeeeeeccc007fe77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ccccccc777cceeeececcccc70ceeeeee27cfcccccccceeee8eefffcccceceeeeccc7777f7782eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ccccccc7cccceeeeecccccc70ceeeeee22c7cfccffcceeeee0f77ffccccceeeeccccccff7722eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
cccccccccccceeeecccccff77f0eeeee2277ffcccccceeeeeec07cccccceeeeeccffccfc7c22eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
cccccccccccceeeececcccfffee8eeee2877f7777ccceeeeeec07ccccceceeeeccccccccfc72eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ccccccccccceeeeeeeccf777ee8eeeeee77ef700ccceeeeeeecc7cfccccceeeeecccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ecccccccccceeeeeececcc77782eeeeee28eefccceeeeeeeeeecccfcccceeeeeecccccccceceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eecccccccceeeeeeeecc722872eeeeeeee28e0eeeeeeeeeeeeeccccccceeeeeeeeccecceeceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeecccceeeeeeeeeeee2222eeeeeeeeeeee8eeeeeeeeeeeeeeecccceeeeeeeeeeeccecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
__label__
1c1111111111111111111111111111111111c11111111111111111111111111111111111c11111111111111111111111111111111111c1111111111111111111
1111111111111111111111111111111c1111111111111111111111111111111111c11111111111111111111111111111111111c1111111111111111111111111
111111111111c11111111111111111111111111111111111c11111111111111111111111111111111111c111111111111111111111111111111111111c111111
b11111111111111bb1111111111111111b111111111111111111111111111111b11111111111111bb1111111111111111b111111111111111111111111111111
b11111111111111bb111b111111111111b111111111b11b1b111111111111111b11111111111111bb111b111111111111b111111111b11b1b111111111111111
b1111b1111111b1bbbb1b1111111b1111b111111111b11b1b1b1111111111111b1111b1111111b1bbbb1b1111111b1111b111111111b11b1b1b1111111111111
b1111b11111b1b1bbbbbb1111111b1111b1bb111111b11b1bbb11b1b111b11b1b1111b11111b1b1bbbbbb1111111b1111b1bb111111b11b1bbb11b1b111b11b1
bb111b11111b1bbbbbbbb11111b1b111bb1bb111111b11b1bbb11b1bb11b11b1bb111b11111b1bbbbbbbb11111b1b111bb1bb111111b11b1bbb11b1bb11b11b1
bbbb1b1b1bbb1bbbbbbbbb111bb1b1b1bb1bbb1111bb11b1bbbb1bbbb1bb11b1bbbb1b1b1bbb1bbbbbbbbb111bb1b1b1bb1bbb1111bb11b1bbbb1bbbb1bb11b1
bbbbbbbb1bbb1bbbbbbbbb111bbbb1b1bb1bbb11b1bbb1bbbbbb1bbbbbbb1bb1bbbbbbbb1bbb1bbbbbbbbb111bbbb1b1bb1bbb11b1bbb1bbbbbb1bbbbbbb1bb1
bbbbbbbb1bbbbbbbbbbbbb111bbbbbbbbbbbbb11b1bbbbbbbbbbbbbbbbbb1bbbbbbbbbbb1bbbbbbbbbbbbb111bbbbbbbbbbbbb11b1bbbbbbbbbbbbbbbbbb1bbb
bbbbbbbb3bbbbbbbbbbbbb3113bbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbb3113bbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbb3bbbbb3bbbbbbb3b13bbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbb3bbbbb3bbbbbbb3b13bbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbb
bbb3b3bb3bbbbb3bbbbbbb3bb3bbbbb333bbbbbbbbbbbb3bbbbbbb3bbbbb3bbbbbb3b3bb3bbbbb3bbbbbbb3bb3bbbbb333bbbbbbbbbbbb3bbbbbbb3bbbbb3bbb
33b3b3b33bbbbb3bbbbb333bb33bb3b333bbbbbbbbbbbb3bbbb3bb3bbbbb33bb33b3b3b33bbbbb3bbbbb333bb33bb3b333bbbbbbbbbbbb3bbbb3bb3bbbbb33bb
3333b3b33b33bb3bbb33333bb333b3b333b3bbb3bbbbbb33bbb3bb3bbbbb33b33333b3b33b33bb3bbb33333bb333b3b333b3bbb3bbbbbb33bbb3bb3bbbbb33b3
3333b3333b33bb3bb333333bb33333b333b3bb33bb3bbb33bbb3bb3b3b3b33b33333b3333b33bb3bb333333bb33333b333b3bb33bb3bbb33bbb3bb3b3b3b33b3
3333b33333333b33b33333333333333333333b33333bbb33b333333b333b33b33333b33333333b33b33333333333333333333b33333bbb33b333333b333b33b3
3333333333333333333333333333333333333b33333b3b333333333b333b33b33333333333333333333333333333333333333b33333b3b333333333b333b33b3
33333333333b3333333333333333333333333bb3333333333333b333333b33b333333333333b3333333333333333333333333bb3333333333333b333333b33b3
3333b33b333b3333b3b33333333333333333bbb3333333333333b333333333b33333b33b333b3333b3b33333333333333333bbb3333333333333b333333333b3
3333b3bb333b3333b3b333333333333b3b33bbb333b3333b3333b333333b3bb33333b3bb333b3333b3b333333333333b3b33bbb333b3333b3333b333333b3bb3
3333b3bb33bb33b3b3b33333333b33bb3b33bbb333b3333b33b3b33333bb3bb33333b3bb33bb33b3b3b33333333b33bb3b33bbb333b3333b33b3b33333bb3bb3
b333b3bb33bbb3b3b3b333bb333bb3bb3b33bbbb33bb33bb33bbb3333bbb3bbbb333b3bb33bbb3b3b3b333bb333bb3bb3b33bbbb33bb33bb33bbb3333bbb3bbb
b333bbbb3bbbbbb3bbb3b3bb33bbb3bb3b3bbbbbb3bb3bbb33bbbbb33bbb3bbbb333bbbb3bbbbbb3bbb3b3bb33bbb3bb3b3bbbbbb3bb3bbb33bbbbb33bbb3bbb
b333bbbbbbbbbbb3bbbbbbbbb3bbb3bbbb3bbbbbb3bb3bbb33bbbbb33bbbbbbbb333bbbbbbbbbbb3bbbbbbbbb3bbb3bbbb3bbbbbb3bb3bbb33bbbbb33bbbbbbb
b333bbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbb3bbbbbb3bbbbbbb3bbbbbbbb333bbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbb3bbbbbb3bbbbbbb3bbbbbbb
b33bbbbbbb3bbbbbbbbbb3bbb3bbbbbbbbbbbbbbb3bbbbbbb3bbbb3bbbbbbbbbb33bbbbbbb3bbbbbbbbbb3bbb3bbbbbbbbbbbbbbb3bbbbbbb3bbbb3bbbbbbbbb
bbbbbbbbbb3bbbbbbbb3b3bbb3bbbbbbbbbbbbbbb3bbbbbbb3bbbb3bbbb3bbbbbbbbbbbbbb3bbbbbbbb3b3bbb3bbbbbbbbbbbbbbb3bbbbbbb3bbbb3bbbb3bbbb
bbbbbbbbbb33bbb3bbb3b3bbb33bbbbbbbbbbbbbb3b3bbbbb3bbbb33bbb3bbbbbbbbbbbbbb33bbb3bbb3b3bbb33bbbbbbbbbbbbbb3b3bbbbb3bbbb33bbb3bbbb
bbbbbbbbbb33bbb3bbb3b3b3b33b3b3bbbbb33b3b3b33bbbb3b33b33b3333bbbbbbbbbbbbb33bbb3bbb3b3b3b33b3b3bbbbb33b3b3b33bbbb3b33b33b3333bbb
bbbbbbbbbb33bbb3bbb3b333b33b3b3bbb3b33b3b3b33b3bb3333b33b3333bbbbbbbbbbbbb33bbb3bbb3b333b33b3b3bbb3b33b3b3b33b3bb3333b33b3333bbb
bbbbb3bbbb33bb33b3b3b333b33b3b3bbb3333b3b3b3333bb3333b3333333bbbbbbbb3bbbb33bb33b3b3b333b33b3b3bbb3333b3b3b3333bb3333b3333333bbb
3bbbb3bbbb333b33b3b33333b33b3b3bb33333b3b3333333b3333333333333bb3bbbb3bbbb333b33b3b33333b33b3b3bb33333b3b3333333b3333333333333bb
3b3bb3bb33333b333333333333333b3bb33333b33333333333333333333333bb3b3bb3bb33333b333333333333333b3bb33333b33333333333333333333333bb
3b33b33b333333333333333333333b3bb33333b33333333333333333333333333b33b33b333333333333333333333b3bb33333b3333333333333333333333333
3b33333333333333333333333333333bb33333b33333333333333333333333333b33333333333333333333333333333bb33333b3333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333bb33333333333333333333333333333333333333333333333333333333333333bb3333333333333333333333
33333333333333333333333333333333333333b3bb333333333333333333333333333333333333333333333333333333333333b3bb3333333333333333333333
33333333333333333333333333333333333333b3bb33bb33333333333333333333333333333333333333333333333333333333b3bb33bb333333333333333333
333333333333333333333333333333b333bbb3bbbbbbbb333333333333333333333333333333333333333333333333b333bbb3bbbbbbbb333333333333333333
33333333333333333333333333333bb333bbbbbbbbbbbb3333b333333333333333333333333333333333333333333bb333bbbbbbbbbbbb3333b3333333333333
33333333333333333333333333b33bbb33bbbbbbbbbbbbb3b3b3333b3333333333333333333333333333333333b33bbb33bbbbbbbbbbbbb3b3b3333b33333333
333333333333333333333ccccccbb1bbbbbbbbbbbbbbbbbbbbbbb33b3333333333333333333333333333333bb3bbbbbbbbbbbbbbbbbbbbbbbbbbb33b33333333
33333333333333333b33cb3cccccccbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333b333b3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
b333333bb33333333b33bccffcccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bb333333bb33333333b33bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b
b333b33bbbb333333b33cccfcc7cccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbb333b33bbbb333333b33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb
bbbbbb3bbbbbb33bbb3cccccc770ccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbb33bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbcbb1cc770cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbccccf77f0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbcbcccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbb1fccf7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9bbb7777777777777777
bbbbbbbbbbbbbbbbbbbbbbb777cf77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9bbbb9b9bbb7777777777777777
bbbbbbbbbbbbbbbbbbbbbbb7777c77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9bbb9bb9bbbb9b9bbb7777777777777777
bbbbbbbbbbbbbbbbbbbbbbbb77bcbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9bbbb9bb99bbb9bbbbbbbbb7777777777777777
bbbbbbbbbbbbbbbbbbbbbbbbbcbcbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9bb9b9bb93bbb9bbbbb9bbb7777777777777777
bbbbbbbbbbbbbbbbbbbbb9bbb7b739bbb3bbbbbbb3bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9bb9bb9bb9bbbbb3bbbbbb3bbbbb37777777777777777
bbbbbbbbbbbbbbbbbb9b99bb08720883bb3b9b9bb33b33b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9b99b9bbbbb93b9bb3bbbbbb33b3b307777777777777777
bbbbbbbbbbbbbbbbb9bb9bbb27888028bb39b9b9b33333b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99b99bb3bbbbb3b9bbbb3b3b330303007777777777777777
bbbbb9bbbbb9bb9bb9b39b9bb9b39b9bb9b9b9b9b93393b33bb3b9bbbbbbb9bbbbb9bb9bb9b9b9b99bbb9bbbbbbbbbb3bbbbbbb3000000047777777777777777
bb9bb9b99bb9bb9bb9bbbb9bb9bbbb9bb9bbb9bbb9bb93393b9339b9bb9bb9b99bb9bb9bb9bbb9bbbbbbbbbbbb0bb3b3bb0bb3b3044040047777777777777777
bb9bb9b99bbbbb9bbbbbbbbbbbbbbbbbbbbbbbbbb9bbbbb9bb9bb9b9bb9bb9b99bbbbb9bbbbbbbbbbbbb300b3003b0303003b030444444047777777777777777
bbbbb9bbbbb93bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb39bbbbbbbb9bbbbbbb9bbbbb93bbbbbbbbbbbb3bb04030040300400403004444444447777777777777777
bbbbbbbbbbbb03bbbbb3bbbbbbb3bbbbbbbb0bbbbb30bbbbbbbbbbbbbbbbbbbbbbbb03bbbbbb0bbbb0bb44404444004444440044444444447777777777777777
bbbb3bbbb3bb03b3bbb030b0bbb030b0b03b03bbbb30bb3bbbbb3bbbbbbb3bbbb3bb03b3b03b03bb30b344404444404444444044944444447777777777777777
b3b30b33b0b3003033b0003033b00030000b00b0b3003b0bb3b30b33b3b30b33b0b30030000b00b000b444444444444444444449944944447777777777777777
0300030300000000030040000300400004030030b000000003000303030003030000000004030030403444449449444444449449994444447777777777777777
44404400000440404440440000044040444044000004404044404400000440404440440077777777777777777777777777777777777777777777777777777777
44444440404444444444444040444444444444404044444444444440404444444444444077777777777777777777777777777777777777777777777777777777
44444444444444444444444444444444444444444444444444444444444444444444444477777777777777777777777777777777777777777777777777777777
94444444444449499444444444444949944444444444494994444444444449499444444477777777777777777777777777777777777777777777777777777777
94944444444444499494444444444449949444444444444994944444444444499494444477777777777777777777777777777777777777777777777777777777
99444444444494999944444444449499994444444444949999444444444494999944444477777777777777777777777777777777777777777777777777777777
49494444444494994949444444449499494944444444949949494444444494994949444477777777777777777777777777777777777777777777777777777777
49494444444494494949444444449449494944444444944949494444444494494949444477777777777777777777777777777777777777777777777777777777
99494444444444499949444444444449994944444444444999494444444444499949444477777777777777777777777777777777777777777777777777777777
94444444444449499444444444444949944444444444494994444444444449499444444477777777777777777777777777777777777777777777777777777777
94444444444449499444444444444949944444444444494994444444444449499444444477777777777777777777777777777777777777777777777777777777
99494444444444499949444444444449994944444444444999494444444444499949444477777777777777777777777777777777777777777777777777777777
99444444444444499944444444444449994444444444444999444444444444499944444477777777777777777777777777777777777777777777777777777777
99944444444494949994444444449494999444444444949499944444444494949994444477777777777777777777777777777777777777777777777777777777
99494444444494949949444444449494994944444444949499494444444494949949444477777777777777777777777777777777777777777777777777777777
99494444444494999949444444449499994944444444949999494444444494999949444477777777777777777777777777777777777777777777777777777777
99494444444444499949444444444449994944444444444999494444444444499949444477777777777777777777777777777777777777777777777777777777
94444444444449499444444444444949944444444444494994444444444449499444444477777777777777777777777777777777777777777777777777777777
94444444444449499444444444444949944444444444494994444444444449499444444477777777777777777777777777777777777777777777777777777777
99494444444444499949444444444449994944444444444999494444444444499949444477777777777777777777777777777777777777777777777777777777
99444444444444499944444444444449994444444444444999444444444444499944444477777777777777777777777777777777777777777777777777777777
99944444444494949994444444449494999444444444949499944444444494949994444477777777777777777777777777777777777777777777777777777777
99494444444494949949444444449494994944444444949499494444444494949949444477777777777777777777777777777777777777777777777777777777
99494444444494999949444444449499994944444444949999494444444494999949444477777777777777777777777777777777777777777777777777777777
99494444444444999949444444444499994944444444449999494444444444999949444477777777777777777777777777777777777777777777777777777777
99444444444494999944444444449499994444444444949999444444444494999944444477777777777777777777777777777777777777777777777777777777
94494444434499999449444443449999944944444344999994494444434499999449444477777777777777777777777777777777777777777777777777777777
994944444b343949994944444b343949994944444b343949994944444b3439499949444477777777777777777777777777777777777777777777777777777777
999944443bb4b949999944443bb4b949999944443bb4b949999944443bb4b9499999444477777777777777777777777777777777777777777777777777777777
999944b3bbbb3999999944b3bbbb3999999944b3bbbb3999999944b3bbbb3999999944b377777777777777777777777777777777777777777777777777777777
993b43bbb33bb939993b43bbb33bb939993b43bbb33bb939993b43bbb33bb939993b43bb77777777777777777777777777777777777777777777777777777777
393b3bbbbb33b3b3393b3bbbbb33b3b3393b3bbbbb33b3b3393b3bbbbb33b3b3393b3bbb77777777777777777777777777777777777777777777777777777777
bb3b3bbbbb3bbb3bbb3b3bbbbb3bbb3bbb3b3bbbbb3bbb3bbb3bbb3bbb3b3bbbbb3bbb3b77777777777777777777777777777777777777777777777777777777
b3bb33bbb333bb3bb3bb33bbb333bb3bb3bb33bbb333bb3bb333bb3bb3bb33bbb333bb3b77777777777777777777777777777777777777777777777777777777
03b3bbbbb3b3b3b003b3bbbbb3b3b3b003b3bbbbb3b3b3b0b3b3b3b003b3bbbbb3b3b3b077777777777777777777777777777777777777777777777777777777
b03bbb333bbbbbb0b03bbb333bbbbbb0b03bbb333bbbbbb03bbbbbb0b03bbb333bbbbbb077777777777777777777777777777777777777777777777777777777
b333bbbbb33b30bbb333bbbbb33b30bbb333bbbbb33b30bbb33b30bbb333bbbbb33b30bb77777777777777777777777777777777777777777777777777777777
b3bbb3bb30033bbbb3bbb3bb30033bbbb3bbb3bb30033bbb30033bbbb3bbb3bb30033bbb77777777777777777777777777777777777777777777777777777777
3bb330bbbb3b33bb3bb330bbbb3b33bb3bb330bbbb3b33bbbb3b33bb3bb330bbbb3b33bb77777777777777777777777777777777777777777777777777777777
bbbbb0bbb33bb3bbbbbbb0bbb33bb3bbbbbbb0bbb33bb3bbb33bb3bbbbbbb0bbb33bb3bb77777777777777777777777777777777777777777777777777777777
bb3b3bbbbb3bbb3bbb3b3bbbbb3bbb3bbb3b3bbbbb3b3bbbbb3bbb3bbb3b3bbbbb3b3bbb77777777777777777777777777777777777777777777777777777777
b3bb33bbb333bb3bb3bb33bbb333bb3bb3bb33bbb3bb33bbb333bb3bb3bb33bbb3bb33bb77777777777777777777777777777777777777777777777777777777
03b3bbbbb3b3b3b003b3bbbbb3b3b3b003b3bbbb03b3bbbbb3b3b3b003b3bbbb03b3bbbb77777777777777777777777777777777777777777777777777777777
b03bbb333bbbbbb0b03bbb333bbbbbb0b03bbb33b03bbb333bbbbbb0b03bbb33b03bbb3377777777777777777777777777777777777777777777777777777777
b333bbbbb33b30bbb333bbbbb33b30bbb333bbbbb333bbbbb33b30bbb333bbbbb333bbbb77777777777777777777777777777777777777777777777777777777
b3bbb3bb30033bbbb3bbb3bb30033bbbb3bbb3bbb3bbb3bb30033bbbb3bbb3bbb3bbb3bb77777777777777777777777777777777777777777777777777777777
3bb330bbbb3b33bb3bb330bbbb3b33bb3bb330bb3bb330bbbb3b33bb3bb330bb3bb330bb77777777777777777777777777777777777777777777777777777777
bbbbb0bbb33bb3bbbbbbb0bbb33bb3bbbbbbb0bbbbbbb0bbb33bb3bbbbbbb0bbbbbbb0bb77777777777777777777777777777777777777777777777777777777

__gff__
0041414141414141414141414141414141414141414141414141414141414141414141414141414141414141410080414141414141414141414141414141414141414141414141414141616180808000418080414141414141414040414141414545454343434343454541414141414145455149434343434545000041418080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000006e6f6e6f6e6f6e6f6f6e6f6e6f6e6f6e6f6e6f6e49466e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f497e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f000000000000000000007c7d7c7d7c7d7c7d1e1f1e1f1e1f1e1f5e5f5e5f5f
000000000000000000006e6f6e6f6e6f6e6f6f585945434443454244455554307e7f7e7f7e7f7e7f7e7f7e7f7e2e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6f6f6e6f6e6f6e6f6e6f6e6f44417000000000000000000000000000000000000000000000000000000000000000000000000000007c7d5e5f5e5f5e5f6e6f6e6f6f
000000000000000000006e6f6e6f6e6f6e6f6f7c7d7c7d535453545354531f40000000000000000000000000002e6e6f6e6f6e6f6e6f6f584345436e6f6e6f6e6f6e6f6e6e6f6e6f6e6f520000000000000000000000000000000000000000000000000000000000000000000000000000000000516e6f6e6f6e6f7e7f7e7f7f
000000000000000000006e6f6e6f6e6f6e6f6f2e0000001e1f1e1f1e1f1e1f504d4e7a4c4e00000000000000000057464344464344425853547c7d002e2e2e6e6f6e6f6e6f2e2e2e2e2e000000000000000000000000000000000000000000000000000000000000000000000000000000000000007e7f7e7f7e7f0000000000
000000000000000000006e6f6e6f6e6f6e6f6e2e0000005e5f5e5f5e5f5e5f6e48454645415200000000000000002f2f2f2f2f2f2f2f307d70000000002e2e2e2e2e2e2e2e2e000000000000000000000000000000007a0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000006e6f6e6f6e6f6e6f6e2e0000516e6f6e6f6e6f6e6f49582f2f2f7d0000004d4c000000002f2f2f2f2f2f2f2f70000000000000002e2e2e2e2e2e2e000000000000000000000000000000005c5d0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000006e6f6e6f6e6f6e6f6f2e0000007e7f7f7e7e7f6f582f2f2f2f7d000000514342520000007c7d2f2f7c7d7c7d000000000000000000000000000000000000000000004e4d4d4c4d4e5c5d4e6c6d4d00000000000000000000000000004d4e7a4c4d00000000000000004e4e4c4d4e4c4d4d4c00000000
000000000000000000006e6f6e6f6e6f6e6f6f2e0000000000000000007f7c7c7d7c7d00000000007c7d0000000000007c7d00000000000000000000000000000000000000000000000000514241424441564146424445483c3d0000000000000000000000514344454943520000000000005142414643424246464352000000
000000000000000000006e6f6e6f6e6f6e6f6f2e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000535453545354535453542f5759425200000000000000000000005354305354000000000000000040407172007374404000000000
000000000000000000006e6f6e6f6e4543444352000000000000000000000000000000000000000000000000000000000000000000000000004d4e000000004d4e4d38393434343d000000001e1f1e1f1e1f1e1f1e1f5e5f7c7d000000000000000000000000757c7d7c70000000000000000040680000000000674000000000
000000000000000000004542444558535453544c4e7a4d4c4d000000000000000000000000000000000000000000000000000000004e4d4c5147493132323b4745444644454342463c3d4d4c1e1f1e1f1e1f1e1f5e5f6e6f00000000000000000000000000000000000000000000000000000040780000000000774000000000
0000000000000000000030535453541e1f1e1f5642454344555200000000000000000000000000000000004d4d000000004c393a3b49444644555357454442585354535453545354594542561e1f1e1f5e5f5e5f6e6f7f7e00000000000000000000000000000000000000000000000000000040000000000000004000000000
00000000000000000000401e1f1e1f1e1f1e1f535453545354004d4e00000000000000000000000000005143463132323b4749455554535453545354535453541e1f1e1f1e1f1e1f1e1f1e1f5e5f5e5f6e6f6e6f7e7f000000000000000000000000000000000000000000000000000000000067690000000000664000000000
00000000000000000000401e1f1e1f1e1f1e1f1e1f1e1f7c7d514142520000000000000000000000000000535459454542555354531f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f5e5f6e6f6e6f7f7e7f7e0000000000000000000000000000000000000000000000000000000000000077790000000000766800000000
000000000000000000007c7d7c7d7c7d7c7d1f1e1f1e7d0000007c7d0000000000000000000000000000007c2f53545354301e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f5e5f6e6f7f7e7e7f00000000000000000000005c5d00004d4c000000000000000000000000000051313335377561624c6364407800000000
0000000000000000000000000000000000007c1e1f7d000000000000000000000000000000004e4d000000007c5e5f5e5f505e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f6e6f7f7e0000000000000000000000005c5d006c6d005143463c3d000000005c5d0000000000000057444447474955595854533c3d000000
000000000000000000000000000000000000007c7d0000000000000000000000000000000051424152000000006e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f7e7f000000000000000000004c5c5d4e6c6d4c6c6d4c4e1e1f59483c3d00006c6d00000000000000535453595854535453544059483c3d4c
00000000000000000000000000000000000000000000000000000000000000000000000000007c7d00000000007e7e7f7e7f7e7f7e7f7f7e7e7e7f7e7e7f7f7e7f7e7e7f7e7f7e7f00000000000000000000005142434649434646474848481e1f1e57594546434549434631330000001e1f1e1f1e1f1e1f1e1f404057444243
00000000000000000000000000000000000000000000000000000000000000004a4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004d4c00007c7d7c402f2f2f576e6f6e5e5f5e5f5e5f5e5f5e5f5e5f57555200005e5f5e5f5e5f5e5f5e5f50505e5f5e5f
0000000000000000000000000000000000000000000000000000000000000051434252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051434152000000004071727374596e6f6e6f6e6f6e6f6e6f6e6f6e6f7c7d0000516e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f
00000000000000000000000000000000000000000000000000000000000000007c7d000000000000000000000000004c4e5c5d4e4c5c5d4e4c4c000000000000000000000000000000000000000000007c7d00000000006800000000677e7f7f7e7f7f7e7e7e7f7e7f7e7f00000000002e2e2e2e2e2e2e2e2e2e2e2e6e6f6e6f
00000000000000000000000000000000000000000000000000000000000000000000000000000000004e4c38393a3b47484847484847484748473133000000000000000000000000000000000000000000000000000000780000000077000000000000000000000000000000000000000000000000000000000000002e2e2e2e
00000000000000000000000000000000000000000000000000000000000000000000000000000000514346474849414343445556434649424143414252000000000000000000000000000000000000000000000000000069000000006600000000000000000000000000000000000000000000000000000000000000002e2e2e
00000000000000000000000000004c4e0000000000000000000000000000004c4c4e4d4a4b4e4d4c4d535457585354535453545354535453545e5f7d000000000000000000000000000000004d4c5c5d4e4d4e000000007900000000760000000000000000000000000000000000004e4c000000000000000000000000002e2e
4d000000004c0000000038393a3b45463c3d00000000000000000000000066564142434142414346555e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f6e6f0000000000000000000000000000000051434455434441463133353740616263644000000000000000000000000000000000005144463c3d0000000000000000000000002e
483132323b473132323b45424155535457463c3d000000000000000000007653545354535453545e5f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f7f7e00000000000000000000000000004e4e4d53545354535430574447474748495853543c3d00000000006570000000000000000000535457463c3d4d4e5c5d00004d4e4c4e4c
41434649414243444558535453541e1f535457443c3d0000000000000065401e1f1e1f1e1f5e5f6e6f6e6f7e7f7e7f7e7f2e2e2e2e2e2e2e2e000000000000000000000000000000514149561e1f1e1f1e1f40301e5945445854401e1f42463c3d4d636470000000000000000000001e1f535459434245424152514441454645
535453545354535453541e1f1e1f1e1f1e1f535459463c3d000000636440401e1f1e1f5e5f6e6f6e6f6e6f0000000000002e2e2e2e2e2e2e2e00000000000000000000000000004e4e301e1f1e1f1e1f1e1f40401e545354531f505e5f5e5f59454455700000004c4e4d4c4d4e4a4b1e1f1e1f535430307c7d00003053545354
5e5f5e5f5e5f5e5f5e5f5e5f5e5f1e1f1e1f5e5f53545741424341584050505e5f5e5f6e6f6e6f6e6f6e6f00000000004d2e2e2e2e2e2e2e2e4d00000000000000000000003e3f4749401e1f1e1f1e1f1e1f50501e1f1e1f1e1f7e7f7e7f7e000000000000006556444246555644451e1f1e1f1e1f407d00000000401e1f1e1f
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e5f535453545354506e6f6e6f6e6f6e6f6e6f6e6f6e6f00007a005148474748484748474748313335374e4d4c4d4c3e3f47495830505e5f5e5f5e5f5e5f6e6f5e5f1e1f1e1f000000000000004d4c4d63643053545354535453541e1f1e1f1e1f400000000000401e1f1e1f
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e5f5e5f5e5f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f3536373839495857555859434143444946444748474848474845555354506f6e6f6e6f6e6f6e6f6e6f6e6f5e5f1e1f4d4c7a4e4d3e3f4749445530405e5f5e5f5e5f5e5f5e5f5e5f5e5f504e7a4d3e3f505e5f5e5f
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6e6e48474558535453545354535453545354305745555657445853541e1f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e5f56464748474845555f5e5f50506e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f47484849466e6f6e6f
__sfx__
010c00002d340293402d340293402f3402b3402f3402b340303402d340303402d340323402f340323402f34023340233403062500000306250000021340213403062500000306250000023340233403062500000
010c000030625000000934009345153401534509340093450a3400a34516340163450a3400a34517340173450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c345
010c0000213301d330213301d330233301f330233301f3302433021330243302133026330233302633023330303302b3202f330303202d330303202b3302d320303302b3202f330303202d330303202b3302d320
010c00000000000000306250000030625000003062500000306250000030625000003062500000306250000030625000002334023345000000000030625000002134021345000000000030625000002334023345
010c00003062500000213402134030625000003062500000233402334530625000002134021345306250000024340243403062500000306250000023340233403062500000306250000021340213403062500000
010c00000c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c345
010c0000303302b3202f330303202d330303202b3302d320303302b3202f330303202d330303202b3302d320303302b3202f330303202d330303202b3302d320303302b3202f330303202d330303202b3302d320
010c00000000000000306250000021340213450000000000306250000000000000003062500000000000000030625000002434024345000000000030625000002334023345000000000030625000002134021340
010c00003062500000306250000030625000003062500000306250000030625000003062500000306250000021340213403062500000306250000023340233403062500000306250000024340243403062500000
010c00000c3400c3450c3400c345093400934509340093450a3400a3450a3400a3450b3400b3450b3400b3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c345
010c00002134021340213402134021340213402134021340213402134021340213450000000000000000000030625000002134021345000000000030625000002334023345000000000030625000002434024345
010c00002134021340306250000030625000002334023340306250000030625000002434024340306250000024340243403062500000306250000023340233403062500000306250000030625000003062500000
010c00003062500000213402134500000000003062500000233402334500000000003062500000243402434530625000002434024340243402434530625000002334023340233402334023340233402334023340
010c00003062500000306250000030625000003062500000306250000030625000003062500000306250000030625000003062500000306250000030625000002434024345213402134030625000002434024345
010c00000c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450c3400c3450e3400e3451034010345113401134511340113451d3401d3451134011345113401134511340113451d3401d3451134011345
010c0000303302b3202f330303202d330303202b3302d320303302b3202f330303202d330303202b3302d32000000000000000000000000000000000000000002433024335213302133021330213352433024335
010c00002334023340233402334023340233402334023340233402334023340233450000000000000000000000000000000000000000000000000000000000003062500000306250000021340213453062500000
010c0000233402334030625000002434024345233402334030625000001f3401f3403062500000306250000030625000003062500000306250000021340213452834028345263402634030625000002434024345
010c0000103401034510340103451c3401c345103401034510340103450c3400c3450e3400e3451034010345113401134511340113451d3401d3451134011345113401134511340113451d3401d3451134011345
010c0000233302333023330233352433024335233302333023330233352b3302d33030330303352d3302d33500000000000000000000000000000021330213352833028335263302633026330263352433024335
010c00003062500000233402334530625000003062500000233402334530625000001f3401f3401f3401f34500000000000000000000000000000030625000003062500000306250000026340263453062500000
010c0000233402334030625000002434024345233402334030625000001f3401f3403062500000306250000030625000003062500000306250000030625000002434024345213402134030625000002434024345
010c0000233302333023330233352433024335233302333023330233352b3302d3303033030335343303433500000000000000000000000000000000000000002433024335213302133021330213352433024335
010c00003062500000233402334530625000003062500000233402334530625000001f3401f3401f3401f34500000000000000000000000000000000000000003062500000306250000021340213453062500000
010c0000233402334030625000002434024345233402334030625000001f3401f34030625000003062500000306250000030625000003062500000213402134521340213451d3401d34030625000002134021345
010c0000103401034510340103451c3401c3451034010345103401034510340103451c3401c34510340103450e3400e3450e3400e3451a3401a3450e3400e3450e3400e3450e3400e3451a3401a3450e3400e345
010c0000233302333023330233352433024335233302333023330233352b3302d33030330303352d3302d335000000000000000000000000000000213302133521330213351d3301d3301d3301d3352133021335
010c00003062500000233402334530625000003062500000233402334530625000001f3401f3401f3401f3450000000000000000000000000000003062500000306250000030625000001d3401d3453062500000
010c00001f3401f340306250000021340213451f3401f340306250000018340183403062500000306250000030625000003062500000306250000030625000002434024345213402134030625000002434024345
010c00000c3400c3450c3400c34518340183450c3400c3450c3400c3450c3400c3450e3400e3451034010345113401134511340113451d3401d3451134011345113401134511340113451d3401d3451134011345
010c00001f3301f3301f3301f33521330213351f3301f3301f3301f33518330183301833018330183301833530330303352d330303202933030320263302932030330303352d3303032029330303202633029320
010c000030625000001f3401f345306250000030625000001f3401f34530625000001834018340183401834500000000000000000000000000000000000000003062500000306250000021340213453062500000
010c00002f3302f3352b3302f320323302b3202f330323202f3302f3352b3302f3202b3302f320283302b32030330303352d330303202933030320263302932030330303352d3303032029330303202633029320
010c00002f3302f3352b3302f320323302b3202f330323202f3302f3352b3302f3202b3302f320283302b32030330303352d330303202933030320263302932030330303352d3303032029330303203433034330
010c00001f3401f340306250000021340213451f3401f3403062500000183401834030625000001c3401c3451a3401a3401a3401a3401a3401a34030625000001534015340153401534530625000001334013340
010c00000c3400c3450c3400c34518340183450c3400c3450c3400c3450c3400c3450c3400c3450c3400c34516340163403062500000306250000015340153403062500000306250000013340133403062500000
010c00003062500000303303033534320343252d3302d33530330303352d3302d335303303033534330343352e3302e335293302e32032330293202e330323202e3302e335293302e32032330293202e33032320
010c000034330343351f3401f345306250000030625000001f3401f3453062500000183401834530625000003062500000163401634016340163451a3401a3401a3401a3401a3401a3401a3401a3401a3401a340
010c00001334013345306250000011340113401134011345306250000018340183451a3401a3451c3401c34030625000000934009340093400934530625000000b3400b3400b3400b34530625000000c3400c340
010c00003062500000113401134030625000003062500000103401034030625000000e3400e34030625000000934009340306250000030625000000b3400b340306250000030625000000c3400c3403062500000
010c00002e3302e335293302e32032330293202e330323202e3302e335293302e32032330293202e330323202d3302d335283302d32030330283202d330303202d3302d335283302d32030330283202d33030320
010c00001a3401a3401a3401a3401a3401a3401a3401a3401a3401a345103401034530625000000e3400e3451c3401c3401c3401c3401c3401c3401c3401c3401c3401c3401c3401c3401c3401c3401c3401c340
010c00000c3400c34530625000000e3400e3400e3400e3453062500000183401834521340213451b3401b34030625000001434014340143401434530625000001334013340133401334530625000001134011340
010c000030625000000e3400e34030625000003062500000103401034030625000001534015340306250000014340143403062500000306250000013340133403062500000306250000011340113403062500000
010c00002d3302d335283302d32030330283202d330303202d3302d335283302d32030330283202d330303202c3302c335273302c32030330273202c330303202c3302c335273302c32030330273202c33030320
010c00001c3401c3401c3401c3401c3401c3401c3401c3401c3401c3451034010345306250000015340153451b3401b3401b3401b3401b3401b3401b3401b3401b3401b3401b3401b3401b3401b3401b3401b340
010c0000113401134530625000000f3400f3400f3400f345306250000018340183451b3401b3451a3401a34030625000001334013340133401334530625000000e3400e3400e3400e34530625000002834028340
010c000030625000000f3400f340306250000030625000000e3400e34030625000000c3400c34030625000001334013340306250000030625000000e3400e3403062500000306250000013340133403062500000
010c00002c3302c335273302c32030330273202c330303202c3302c335273302c32030330273202c3303032030330303352d33030320343302d3202d3303432030330303352d33030320343302d3202d33034320
010c00001b3401b3401b3401b3401b3401b3401b3401b3401b3401b3450e3400e34530625000000c3400c3451a3401a3401a3401a3401a3401a3401a3401a3401a3401a3401a3401a3401a3401a3451334013345
010c000030625000002834028345293402934528340283452b3402b34528340283452834028345243402434530625000003062500000306250000030625000002434024345213402134030625000002434024345
010c000013340133451034010345103401034511340113451134011345123401234513340133451134011345113401134511340113451d3401d3451134011345113401134511340113451d3401d3451134011345
010c000030330303352d33030320343302d3202d3303432030330303352d33030320343302d3202d3303432000000000000000000000000000000000000000002433024335213302133021330213352433024335
010c00002834028345306250000030625000003062500000306250000030625000003062500000306250000000000000000000000000000000000000000000003062500000306250000021340213453062500000
010c000030625000002834028345293402934528340283452b3402b34528340283452834028345243402434500000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001334013345103401034510340103451134011345113401134512340123451334013345113401134500000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000030330303352d33030320343302d3202d3303432030330303352d33030320343302d3202d3303432000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002834028345306250000030625000003062500000306250000030625000003062500000306250000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900003f5733f5633f5433f5233f5133f5233f5433f5633f5733f5633f5433f5233f5133f503025030250302503025030250301503025030250302503025030050300503005030050300503005030050300503
010300001354013540145401555016550185501b5601e560235712a56100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00010203
00 04050607
00 0809060a
00 0b05060c
00 0d0e0f10
00 11121314
00 15121617
00 18191a1b
00 1c1d1e1f
00 11122014
00 15122017
00 1819211b
00 22232425
00 26272829
00 2a2b2c2d
00 2e2f3031
00 32333435
00 11121314
00 15121617
00 18191a1b
00 1c1d1e1f
00 11122014
00 15122017
00 1819211b
00 22232425
00 26272829
00 2a2b2c2d
00 2e2f3031
00 32333435
00 11121314
00 15121617
00 18191a1b
00 1c1d1e1f
00 11122014
00 15122017
00 1819211b
00 22232425
00 26272829
00 2a2b2c2d
00 2e2f3031
02 36373839

