-- Balatro-style HD pixel art pass (v0.25). Run AFTER every other art script:
--   * rounded UI skins with a raised lip (32 x 32 nine-slice)
--   * native 48 x 48 candies and Color Bomb, shaded per pixel (lighting, dithered ramps, outlines, glints)
--   * rounded 56 x 56 board tiles
--   * HD cards: every 70 x 94 card/pack/edition PNG is upscaled with Scale2x (smooths jagged diagonals)
--     to 140 x 188, given rounded corners and paper grain, and saved as a new layered master.
--     Images that are already 140 x 188 are skipped, so re-running is safe.
-- Run: Aseprite -b --script-param "root=<project>" --script tools/create_hd_art.lua
local root=app.params["root"]
local SRC=root.."/assets/source/aseprite/"
local OUT=root.."/assets/exported/"
local function rgba(r,g,b,a) return app.pixelColor.rgba(math.floor(r),math.floor(g),math.floor(b),math.floor(a or 255)) end
local function hex(h,a) return rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),a or 255) end
local function clamp(v,a,b) if v<a then return a elseif v>b then return b end return v end
local function layer(s,name)
 local l=s:newLayer();l.name=name;local im=Image(s.width,s.height,ColorMode.RGB);s:newCel(l,1,im);return s.layers[#s.layers]
end
local function save(s,name)
 s:saveAs(SRC..name..".aseprite");s:saveCopyAs(OUT..name..".png");s:close()
end
local function put(cel,x,y,col) cel.image:drawPixel(x,y,col) end

-- Rounded rectangle test (inclusive pixel coords).
local function in_round(x,y,x0,y0,w,h,r)
 if x<x0 or y<y0 or x>x0+w-1 or y>y0+h-1 then return false end
 local cx=clamp(x,x0+r,x0+w-1-r);local cy=clamp(y,y0+r,y0+h-1-r)
 local dx=x-cx;local dy=y-cy
 return dx*dx+dy*dy<=r*r+r*0.8
end

-- UI skins --------------------------------------------------------------------
-- face: main fill; rim: 1 px outline; lip: darker raised bottom; shine: top highlight.
local function skin(name,face,rim,lip,shine,pressed)
 local s=Sprite(32,32,ColorMode.RGB);s.layers[1].name="Lip shadow"
 local lipcel=s.cels[1]
 local facel=layer(s,"Rounded face")
 local fcel=s.cels[#s.cels]
 local top=pressed and 2 or 0
 local bottom=pressed and 31 or 28
 for y=0,31 do for x=0,31 do
  if in_round(x,y,0,3,32,29,7) then put(lipcel,x,y,hex(lip)) end
  if in_round(x,y,0,top,32,bottom-top+1,7) then
   local edge=not in_round(x,y,1,top+1,30,bottom-top-1,6)
   local col=hex(face)
   if edge then col=hex(rim)
   elseif y==top+1 or y==top+2 then col=hex(shine) end
   put(fcel,x,y,col)
  end
 end end
 save(s,name)
end
local function family(name,face,rim,lip,shine,hover_face,hover_rim,pressed_face)
 skin(name,face,rim,lip,shine,false)
 if hover_face then
  skin(name.."_hover",hover_face,hover_rim,lip,shine,false)
  skin(name.."_pressed",pressed_face,rim,lip,face,true)
 end
end
-- Panels (no states).
skin("ui_panel","3b2742","5e3f69","1f1226","4a3152",false)
skin("ui_inset","22142a","3a2544","140a18","2a1932",false)
skin("ui_disabled","3a3040","4f4456","241c29","443a4a",false)
skin("ui_boss","5c2a4a","8a4570","34152a","6c3458",false)
skin("ui_progress_gold","f0b43c","ffd770","a8721a","ffe29a",false)
skin("ui_green","35a06e","5cc48e","1d5e40","58c48e",false)
skin("ui_blue","2f86d6","5aaaf0","1a4f86","56a8ec",false)
-- Default berry button and role buttons, with hover and pressed states.
family("ui_button","d2486e","ef7598","7e2440","e86a8c","e45c82","fff3e6","b03a5c")
family("ui_btn_go","35a06e","5cc48e","1d5e40","58c48e","42b47e","fff3e6","2b8a5c")
family("ui_btn_info","2f86d6","5aaaf0","1a4f86","56a8ec","3a96e8","fff3e6","2672b8")
family("ui_btn_buy","e09a26","ffc45a","8a5410","ffbe4a","f0aa34","fff3e6","c4841c")
family("ui_btn_skip","8a5aa8","a97ac8","4e3066","a87ac6","9a6ab8","fff3e6","744a90")
family("ui_btn_danger","c0394f","e05a6e","6e1c2c","d85a6c","d44a60","fff3e6","a42e42")
family("ui_btn_neutral","5a4466","7a5e88","32243b","715580","6a5278","fff3e6","4c3a57")

-- Per-pixel shaded sprites ------------------------------------------------------
local bayer={{0,8,2,10},{12,4,14,6},{3,11,1,9},{15,7,13,5}}
local function ramp_pick(ramp,v,x,y)
 -- v in 0..1 across the ramp, dithered with a 4x4 Bayer matrix for smooth pixel gradients.
 local n=#ramp
 local f=clamp(v,0,0.9999)*(n-1)
 local i=math.floor(f);local frac=f-i
 if frac>(bayer[y%4+1][x%4+1]+0.5)/16 then i=i+1 end
 return hex(ramp[clamp(i,0,n-1)+1])
end
local function len(x,y) return math.sqrt(x*x+y*y) end
local function sd_circle(x,y,cx,cy,r) return len(x-cx,y-cy)-r end
local function sd_ellipse(x,y,cx,cy,rx,ry) return (len((x-cx)/rx,(y-cy)/ry)-1)*math.min(rx,ry) end
local function sd_box(x,y,cx,cy,hw,hh,r)
 local qx=math.abs(x-cx)-hw+r;local qy=math.abs(y-cy)-hh+r
 return len(math.max(qx,0),math.max(qy,0))+math.min(math.max(qx,qy),0)-r
end
local function sd_capsule(x,y,ax,ay,bx,by,r)
 local px,py=x-ax,y-ay;local vx,vy=bx-ax,by-ay
 local h=clamp((px*vx+py*vy)/(vx*vx+vy*vy),0,1)
 return len(px-vx*h,py-vy*h)-r
end
local function smin(a,b,k)
 local h=clamp(0.5+0.5*(b-a)/k,0,1)
 return b*(1-h)+a*h-k*h*(1-h)
end
local LX,LY,LZ=-0.55,-0.65,0.75
do local l=math.sqrt(LX*LX+LY*LY+LZ*LZ);LX,LY,LZ=LX/l,LY/l,LZ/l end
-- Render a shape given an sdf(x,y) and a colour function(x,y,shade,depth) -> colour.
-- thickness controls how rounded/domed the surface looks.
local function render(name,size,sdf,thickness,colour,outline_col,extras)
 local s=Sprite(size,size,ColorMode.RGB);s.layers[1].name="Soft shadow"
 local shadow=s.cels[1]
 layer(s,"Shaded body");local body=s.cels[#s.cels]
 layer(s,"Outline");local outl=s.cels[#s.cels]
 layer(s,"Glints and details");local det=s.cels[#s.cels]
 local function height(x,y)
  local d=sdf(x,y)
  if d>=0 then return 0 end
  local t=clamp(-d/thickness,0,1)
  return math.sqrt(1-(1-t)*(1-t))
 end
 for y=0,size-1 do for x=0,size-1 do
  local px,py=x+0.5,y+0.5
  local d=sdf(px,py)
  local sd=sdf(px-2,py-3)
  if sd<0 and d>=0 then put(shadow,x,y,rgba(0,0,0,80)) end
  if d<0 then
   local hx=(height(px+0.6,py)-height(px-0.6,py))/1.2
   local hy=(height(px,py+0.6)-height(px,py-0.6))/1.2
   local nx,ny,nz=-hx*thickness*0.55,-hy*thickness*0.55,1
   local nl=math.sqrt(nx*nx+ny*ny+nz*nz);nx,ny,nz=nx/nl,ny/nl,nz/nl
   local shade=nx*LX+ny*LY+nz*LZ
   -- Contrast: the base colour covers most of the body; the brightest tones are kept for highlights.
   shade=clamp((shade-0.45)/0.55,0,1)
   shade=0.14+0.66*shade^1.3
   -- Ambient occlusion near the bottom-right edge, rim light near the top-left edge.
   if d>-2.2 then
    if nx>0.1 or ny>0.1 then shade=shade*0.75 else shade=math.min(1,shade+0.12) end
   end
   put(body,x,y,colour(x,y,shade,-d))
  elseif d<1.6 then
   put(outl,x,y,outline_col)
  end
 end end
 if extras then extras(det) end
 save(s,name)
end
local R={
 red={"4a0d22","8e2238","c23a43","ef5a4f","ff8a78","ffc4b4"},
 yellow={"5c3410","a8661a","e09a26","ffd04a","ffe98a","fff8d0"},
 green={"0f3a24","24683c","3e9a52","6fcf6a","a8ee8c","e0ffd0"},
 blue={"0f2f5c","1d5590","2e86c8","5cc0f0","a8e4ff","e4f8ff"},
 white={"6a7088","a4adc4","d4dbe8","eef2f8","ffffff","ffffff"},
 purple={"2c1648","52307e","7c50b4","b07ee0","d8b0ff","f4e6ff"},
 caramel={"3e2010","7a4422","b06c34","e0a05a","f6c890","fff0d8"},
 choc={"1c0d08","3a2018","5a3426","74462f","9a6646","c49270"},
}
local WHITE=hex("ffffff")
local function spec(det,points) for _,p in ipairs(points) do put(det,p[1],p[2],WHITE) end end

-- 0 Berry Bonbon: glossy sphere with pleated wrapper fans.
render("candy_0",48,function(x,y)
 local body=sd_circle(x,y,24,24,13)
 local left=sd_capsule(x,y,5,24,13,24,7);local right=sd_capsule(x,y,35,24,43,24,7)
 return smin(body,math.min(left,right),2.5)
end,7,function(x,y,shade,depth)
 if math.abs(x-24)>12 then
  local pleat=((y+math.floor(math.abs(x-24)*0.5))%4<2) and 0.12 or -0.05
  return ramp_pick(R.red,shade*0.85+pleat,x,y)
 end
 return ramp_pick(R.red,shade,x,y)
end,hex("3a0618"),function(det)
 spec(det,{{17,17},{18,17},{19,17},{17,18},{16,19},{16,20},{18,18}})
 spec(det,{{29,32},{30,31}})
end)

-- 1 Lemon Drop: faceted gem with a bright table facet.
render("candy_1",48,function(x,y)
 return (math.abs(x-24)+math.abs(y-24))/1.414-14
end,4,function(x,y,shade,depth)
 local dx,dy=x+0.5-24,y+0.5-24
 local v
 if math.abs(dx)+math.abs(dy)<9 then v=0.86
 elseif dx<=0 and dy<=0 then v=0.95
 elseif dx>0 and dy<=0 then v=0.62
 elseif dx<=0 and dy>0 then v=0.48
 else v=0.22 end
 if math.abs(math.abs(dx)-math.abs(dy))<0.8 then v=v+0.08 end
 return ramp_pick(R.yellow,v,x,y)
end,hex("4a2808"),function(det)
 spec(det,{{17,15},{18,14},{19,13},{16,16},{20,13}})
end)

-- 2 Mint Gummy: soft translucent bear.
render("candy_2",48,function(x,y)
 local d=sd_circle(x,y,24,15,9)
 d=smin(d,sd_circle(x,y,16,8,4.5),2);d=smin(d,sd_circle(x,y,32,8,4.5),2)
 d=smin(d,sd_ellipse(x,y,24,31,11,10),3)
 d=smin(d,sd_circle(x,y,13,27,4.5),2);d=smin(d,sd_circle(x,y,35,27,4.5),2)
 d=smin(d,sd_circle(x,y,17,40,5),2);d=smin(d,sd_circle(x,y,31,40,5),2)
 return d
end,6,function(x,y,shade,depth)
 -- Gummy glow: lighter inside the body.
 local glow=clamp(depth/9,0,1)*0.18
 return ramp_pick(R.green,shade*0.9+glow,x,y)
end,hex("0a2a18"),function(det)
 for _,p in ipairs({{20,13},{21,13},{27,13},{28,13},{20,14},{21,14},{27,14},{28,14}}) do put(det,p[1],p[2],hex("0f3a24")) end
 for _,p in ipairs({{23,17},{24,17},{25,17},{24,18}}) do put(det,p[1],p[2],hex("24683c")) end
 spec(det,{{18,9},{19,9},{17,10},{19,24},{20,24},{19,25}})
end)

-- 3 Blue Peppermint: swirl stripes over a domed disc.
render("candy_3",48,function(x,y) return sd_circle(x,y,24,24,16) end,10,function(x,y,shade,depth)
 local dx,dy=x+0.5-24,y+0.5-24
 local a=math.atan(dy,dx)
 local r=len(dx,dy)
 if r<3.5 then return ramp_pick(R.blue,shade,x,y) end
 local stripe=math.sin(a*6+r*0.32)>0.15
 return ramp_pick(stripe and R.blue or R.white,shade,x,y)
end,hex("0a1f44"),function(det)
 spec(det,{{15,14},{16,13},{17,13},{18,12},{14,15},{14,16}})
end)

-- 4 Plum Jellybean: tilted glossy bean with speckles.
render("candy_4",48,function(x,y)
 local d=sd_capsule(x,y,15,31,33,17,10.5)
 return d+0.8*math.max(0,-((x-26)*0.6+(y-27)*0.8)+2)*0
end,8,function(x,y,shade,depth)
 local v=shade
 if (x*7+y*13)%37==0 and depth>3 then v=v+0.25 end
 return ramp_pick(R.purple,v,x,y)
end,hex("1e0c36"),function(det)
 spec(det,{{25,12},{26,12},{27,12},{24,13},{23,14},{12,27},{12,28}})
end)

-- 5 Caramel Square: rounded block with four glossy pillows.
render("candy_5",48,function(x,y) return sd_box(x,y,24,24,16,16,6) end,5,function(x,y,shade,depth)
 local px,py=x+0.5,y+0.5
 local cx=px<24 and 16.5 or 31.5;local cy=py<24 and 16.5 or 31.5
 local pd=sd_box(px,py,cx,cy,6.5,6.5,3)
 if pd>0 then return ramp_pick(R.caramel,shade*0.45,x,y) end
 local t=clamp(-pd/4,0,1)
 local bump=((cx-px)*0.06+(cy-py)*0.07)*(1-t)
 return ramp_pick(R.caramel,clamp(shade*0.75+0.25*t+bump,0,1),x,y)
end,hex("2a1408"),function(det)
 spec(det,{{12,12},{13,12},{12,13},{27,12},{28,12},{27,13},{12,27},{13,27},{27,27},{28,27}})
end)

-- Color Bomb: dark chocolate sphere with shaded sprinkles.
render("candy_bomb",48,function(x,y) return sd_circle(x,y,24,24,16) end,10,function(x,y,shade,depth)
 return ramp_pick(R.choc,shade,x,y)
end,hex("120603"),function(det)
 local cols={R.red,R.yellow,R.green,R.blue,R.purple,R.white}
 local seed=11
 for i=1,16 do
  seed=(seed*1103515245+12345)%2147483648;local a=(seed%628)/100
  seed=(seed*1103515245+12345)%2147483648;local r=4+(seed%11)
  local x=math.floor(24+math.cos(a)*r);local y=math.floor(24+math.sin(a)*r)
  local ramp=cols[i%6+1]
  local horizontal=i%2==0
  for k=0,2 do
   local px=x+(horizontal and k or 0);local py=y+(horizontal and 0 or k)
   put(det,px,py,hex(ramp[k==0 and 5 or 4]))
  end
  put(det,x+(horizontal and 0 or 1),y+(horizontal and 1 or 0),hex(ramp[2]))
 end
 spec(det,{{15,14},{16,13},{17,13},{14,15}})
end)

-- Board tiles: rounded plum wells with a soft top highlight and lower lip.
for _,t in ipairs({{"ui_tile_a","4a3158","5e4170","38243f"},{"ui_tile_b","553a64","6a4c7c","3e2848"}}) do
 local s=Sprite(56,56,ColorMode.RGB);s.layers[1].name="Rounded tile"
 local cel=s.cels[1]
 for y=0,55 do for x=0,55 do
  if in_round(x,y,1,1,54,54,8) then
   local col=hex(t[2])
   if not in_round(x,y,2,2,52,52,7) then col=hex(t[4])
   elseif y<5 then col=hex(t[3])
   elseif y>50 then col=hex(t[4]) end
   put(cel,x,y,col)
  end
 end end
 save(s,t[1])
end

-- HD cards ------------------------------------------------------------------------
local function same(a,b) return a==b end
local function scale2x(src)
 local w,h=src.width,src.height
 local out=Image(w*2,h*2,ColorMode.RGB)
 local function px(x,y)
  x=clamp(x,0,w-1);y=clamp(y,0,h-1)
  return src:getPixel(x,y)
 end
 for y=0,h-1 do for x=0,w-1 do
  local P=px(x,y);local A=px(x,y-1);local B=px(x+1,y);local C=px(x-1,y);local D=px(x,y+1)
  local e1,e2,e3,e4=P,P,P,P
  if same(C,A) and not same(C,D) and not same(A,B) then e1=A end
  if same(A,B) and not same(A,C) and not same(B,D) then e2=B end
  if same(D,C) and not same(D,B) and not same(C,A) then e3=C end
  if same(B,D) and not same(B,A) and not same(D,C) then e4=D end
  out:drawPixel(x*2,y*2,e1);out:drawPixel(x*2+1,y*2,e2);out:drawPixel(x*2,y*2+1,e3);out:drawPixel(x*2+1,y*2+1,e4)
 end end
 return out
end
local function is_paper(c)
 local r,g,b=app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c)
 return app.pixelColor.rgbaA(c)>200 and r>200 and g>185 and b>140 and r>=b+20
end
local INK=hex("1c1022")
local function hd_card(name,round)
 local path=OUT..name..".png"
 if not app.fs.isFile(path) then return end
 local src=Image{fromFile=path}
 if src.width~=70 or src.height~=94 then return end
 local big=scale2x(src)
 local s=Sprite(140,188,ColorMode.RGB);s.layers[1].name="HD art (Scale2x of the original card)"
 s.cels[1].image=big
 layer(s,"Paper grain");local grain=s.cels[#s.cels]
 layer(s,"Rounded frame");local frame=s.cels[#s.cels]
 local base=s.cels[1].image
 for y=0,187 do for x=0,139 do
  local c=base:getPixel(x,y)
  if round then
   if not in_round(x,y,0,0,140,188,10) then
    base:drawPixel(x,y,rgba(0,0,0,0))
   elseif not in_round(x,y,2,2,136,184,9) then
    put(frame,x,y,INK)
   elseif is_paper(c) and ((x*3+y*5)%11==0 or (x+y*2)%17==0) then
    local r,g,b=app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c)
    put(grain,x,y,rgba(r-12,g-12,b-14,255))
   elseif y>=4 and y<=5 and is_paper(c) then
    put(grain,x,y,hex("fff8e8"))
   end
  end
 end end
 save(s,name)
end
local cards={}
for i=0,15 do table.insert(cards,"joker_"..i) end
for _,n in ipairs({"supply_berry","supply_lemon","supply_mint","supply_peppermint","supply_plum","supply_caramel",
 "pop_rock","sweet_tooth","golden_trio","three_scoops","striper","wrapper","bomb_maker","sugar_cube","gumball_jar","candy_cane",
 "sugar_shaker_card","extra_serving","golden_glaze","candy_hammer","edition_foil","edition_holo","edition_poly"}) do table.insert(cards,n) end
for _,n in ipairs(cards) do hd_card(n,true) end
for _,n in ipairs({"pack_joker","pack_recipe","pack_candy","pack_treat","pack_rush","pack_jumbo"}) do hd_card(n,false) end
