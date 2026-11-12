-- Native 140 x 188 Joker cards (v0.26): Balatro-style frame and per-pixel shaded illustrations.
-- Run AFTER tools/create_hd_art.lua (it stamps the HD candies). Overwrites every Joker card and its master.
-- Run: Aseprite -b --script-param "root=<project>" --script tools/create_joker_hd.lua
local root=app.params["root"]
local SRC=root.."/assets/source/aseprite/"
local OUT=root.."/assets/exported/"
local function rgba(r,g,b,a) return app.pixelColor.rgba(math.floor(r),math.floor(g),math.floor(b),math.floor(a or 255)) end
local cache={}
local function hex(h,a)
 local key=h..(a or "")
 if not cache[key] then cache[key]=rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),a or 255) end
 return cache[key]
end
local function clamp(v,a,b) if v<a then return a elseif v>b then return b end return v end
local function len(x,y) return math.sqrt(x*x+y*y) end
local W,H=140,188
local AX,AY,AW,AH=10,34,120,124 -- art window
local CX,CY=AX+AW/2,AY+AH/2

-- Colour ramps, dark to light.
local R={
 red={"3a0618","8e2238","c23a43","ef5a4f","ff8a78","ffc4b4"},
 yellow={"5c3410","a8661a","e09a26","ffd04a","ffe98a","fff8d0"},
 green={"0f3a24","24683c","3e9a52","6fcf6a","a8ee8c","e0ffd0"},
 blue={"0f2f5c","1d5590","2e86c8","5cc0f0","a8e4ff","e4f8ff"},
 white={"6a7088","a4adc4","d4dbe8","eef2f8","ffffff","ffffff"},
 purple={"2c1648","52307e","7c50b4","b07ee0","d8b0ff","f4e6ff"},
 caramel={"3e2010","7a4422","b06c34","e0a05a","f6c890","fff0d8"},
 choc={"1c0d08","3a2018","5a3426","74462f","9a6646","c49270"},
 gold={"5a3a08","9a6a10","d09a20","f4c84a","ffe68a","fff8d8"},
 steel={"1e2430","3c4658","68748a","98a4b8","c8d2e0","f0f4fa"},
 wood={"3a200e","6a3e1c","9a6230","c88a4c","e6b07a","f8dcb0"},
 bone={"5a4a3a","8e7c66","c0ae94","e6d8c0","f8f0e0","ffffff"},
 pink={"5a1438","a0306a","d85a96","ff8ac0","ffbedc","ffe8f4"},
 teal={"0a3a3a","17686a","2e9a96","4ccac0","96ece2","dafff8"},
 orange={"5a2408","a04a12","d8741e","ff9e3a","ffc880","ffeccc"},
 night={"0c0818","1a1030","2a1a48","3c2a64","5a447e","7a64a0"},
 ink={"0a0610","1c1022","2a1a30","3a2742","4a3452","5a4466"},
}
local INK=hex("1c1022")
local bayer={{0,8,2,10},{12,4,14,6},{3,11,1,9},{15,7,13,5}}
local function pick(ramp,v,x,y)
 local n=#ramp
 local f=clamp(v,0,0.9999)*(n-1)
 local i=math.floor(f)
 if f-i>(bayer[y%4+1][x%4+1]+0.5)/16 then i=i+1 end
 return hex(ramp[clamp(i,0,n-1)+1])
end

-- Signed distance helpers (card pixel coordinates).
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
local function sd_ring(x,y,cx,cy,R0,r) return math.abs(len(x-cx,y-cy)-R0)-r end
local function sd_diamond(x,y,cx,cy,rx,ry) return ((math.abs(x-cx)/rx+math.abs(y-cy)/ry)-1)*math.min(rx,ry)*0.7 end
local function rot(x,y,cx,cy,a)
 local c,s=math.cos(a),math.sin(a);local dx,dy=x-cx,y-cy
 return cx+dx*c+dy*s,cy-dx*s+dy*c
end
local function smin(a,b,k)
 local h=clamp(0.5+0.5*(b-a)/k,0,1)
 return b*(1-h)+a*h-k*h*(1-h)
end
local function union(...) local d=1e9 for _,v in ipairs({...}) do if v<d then d=v end end return d end

-- Window mask: rounded art window.
local function in_round(x,y,x0,y0,w,h,r)
 if x<x0 or y<y0 or x>x0+w-1 or y>y0+h-1 then return false end
 local cx=clamp(x,x0+r,x0+w-1-r);local cy=clamp(y,y0+r,y0+h-1-r)
 local dx=x-cx;local dy=y-cy
 return dx*dx+dy*dy<=r*r+r*0.8
end
local function in_window(x,y) return in_round(x,y,AX,AY,AW,AH,6) end

local LX,LY,LZ=-0.55,-0.65,0.75
do local l=math.sqrt(LX*LX+LY*LY+LZ*LZ);LX,LY,LZ=LX/l,LY/l,LZ/l end

-- Draw a shaded shape into image `im`. opts: thick (dome radius), ramp, colour(x,y,shade,depth),
-- outline (colour or false), bbox {x0,y0,x1,y1}, flat (fixed shade), shadow (true for a drop shadow).
local function shape(im,sdf,opts)
 local th=opts.thick or 8
 local bb=opts.bbox or {AX,AY,AX+AW-1,AY+AH-1}
 local outline=opts.outline
 if outline==nil then outline=hex(opts.ramp[1]) end
 local function height(x,y)
  local d=sdf(x,y)
  if d>=0 then return 0 end
  local t=clamp(-d/th,0,1)
  return math.sqrt(1-(1-t)*(1-t))
 end
 if opts.shadow then
  for y=bb[2],bb[4]+4 do for x=bb[1],bb[3]+3 do
   if in_window(x,y) and sdf(x+0.5-3,y+0.5-4)<0 and sdf(x+0.5,y+0.5)>=1.6 then
    local c=im:getPixel(x,y)
    im:drawPixel(x,y,rgba(app.pixelColor.rgbaR(c)*0.6,app.pixelColor.rgbaG(c)*0.6,app.pixelColor.rgbaB(c)*0.66,255))
   end
  end end
 end
 for y=bb[2],bb[4] do for x=bb[1],bb[3] do
  if in_window(x,y) then
   local px,py=x+0.5,y+0.5
   local d=sdf(px,py)
   if d<0 then
    local shade
    if opts.flat then shade=opts.flat else
     local hx=(height(px+0.7,py)-height(px-0.7,py))/1.4
     local hy=(height(px,py+0.7)-height(px,py-0.7))/1.4
     local nx,ny,nz=-hx*th*0.55,-hy*th*0.55,1
     local nl=math.sqrt(nx*nx+ny*ny+nz*nz);nx,ny,nz=nx/nl,ny/nl,nz/nl
     shade=nx*LX+ny*LY+nz*LZ
     shade=clamp((shade-0.45)/0.55,0,1)
     shade=0.14+0.66*shade^1.3
     if d>-2.2 then if nx>0.1 or ny>0.1 then shade=shade*0.78 else shade=math.min(1,shade+0.1) end end
    end
    local col
    if opts.colour then col=opts.colour(x,y,shade,-d) else col=pick(opts.ramp,shade,x,y) end
    if col then im:drawPixel(x,y,col) end
   elseif outline and d<(opts.outline_width or 1.8) then
    im:drawPixel(x,y,outline)
   end
  end
 end end
end
local function glint(im,points) for _,p in ipairs(points) do if in_window(p[1],p[2]) then im:drawPixel(p[1],p[2],hex("ffffff")) end end end
local function sparkle(im,x,y,r,col)
 col=col or hex("fff8d0")
 for k=-r,r do
  if in_window(x+k,y) then im:drawPixel(x+k,y,col) end
  if in_window(x,y+k) then im:drawPixel(x,y+k,col) end
 end
 if r>2 then for k=-1,1 do for j=-1,1 do if in_window(x+k,y+j) then im:drawPixel(x+k,y+j,col) end end end end
end
-- Stamp an exported sprite (e.g. HD candies) at a given scale (nearest).
local function stamp(im,name,x,y,scale)
 local src=Image{fromFile=OUT..name..".png"}
 local w,h=math.floor(src.width*scale),math.floor(src.height*scale)
 for yy=0,h-1 do for xx=0,w-1 do
  local p=src:getPixel(math.floor(xx/scale),math.floor(yy/scale))
  local a=app.pixelColor.rgbaA(p)
  if a>200 and in_window(x+xx,y+yy) then im:drawPixel(x+xx,y+yy,p)
  elseif a>40 and in_window(x+xx,y+yy) then
   local c=im:getPixel(x+xx,y+yy)
   im:drawPixel(x+xx,y+yy,rgba(app.pixelColor.rgbaR(c)*0.65,app.pixelColor.rgbaG(c)*0.65,app.pixelColor.rgbaB(c)*0.7,255))
  end
 end end
end

-- Backgrounds.
local function background(im,ramp,style)
 for y=AY,AY+AH-1 do for x=AX,AX+AW-1 do
  if in_window(x,y) then
   local t=(y-AY)/AH
   local v=0.62-0.4*t
   if style=="rays" then
    local a=math.atan(y-CY,x-CX)
    if math.floor((a+math.pi)/(math.pi/8))%2==0 then v=v+0.12 end
   elseif style=="dots" then
    if ((x-AX)%14<4 and (y-AY)%14<4) then v=v+0.12 end
   elseif style=="grid" then
    if (x-AX)%12==0 or (y-AY)%12==0 then v=v+0.1 end
   elseif style=="stripes" then
    if math.floor((x+y)/10)%2==0 then v=v+0.08 end
   elseif style=="glow" then
    v=0.75-len(x-CX,y-CY)/90
   end
   im:drawPixel(x,y,pick(ramp,clamp(v,0.05,0.85)*0.75,x,y))
  end
 end end
 if style=="stars" or style=="glow" then
  local seed=7
  for i=1,14 do
   seed=(seed*1103515245+12345)%2147483648;local x=AX+6+seed%(AW-12)
   seed=(seed*1103515245+12345)%2147483648;local y=AY+6+seed%(AH-12)
   sparkle(im,x,y,i%4==0 and 3 or 1,hex(ramp[#ramp]))
  end
 end
end

-- Lettering from the m6x11 atlas, at 2x, proportional.
local atlas=Image{fromFile=OUT.."font_atlas.png"}
local function glyph_width(code)
 local ax=(code%16)*16;local ay=math.floor(code/16)*20
 local w=0
 for y=0,11 do for x=0,10 do if app.pixelColor.rgbaA(atlas:getPixel(ax+x,ay+y))>0 and x+1>w then w=x+1 end end end
 return w
end
local function title(im,text,col)
 local widths={};local total=0
 for i=1,#text do
  local code=string.byte(text,i)-32
  local w=code==0 and 3 or glyph_width(code)
  widths[i]=w;total=total+(w+1)*2
 end
 total=total-2
 local x0=math.floor((W-total)/2);local y0=9
 for i=1,#text do
  local code=string.byte(text,i)-32
  local ax=(code%16)*16;local ay=math.floor(code/16)*20
  for y=0,11 do for x=0,10 do
   if app.pixelColor.rgbaA(atlas:getPixel(ax+x,ay+y))>0 then
    for dy=0,1 do for dx=0,1 do im:drawPixel(x0+x*2+dx,y0+y*2+dy,col) end end
   end
  end end
  x0=x0+(widths[i]+1)*2
 end
end

-- Card frame.
local CATEGORY={Geometry={"blue","5cc0f0"},Four={"green","6fcf6a"},Five={"purple","b07ee0"},Chaos={"red","ef5a4f"},
 Supply={"caramel","e0a05a"},Three={"pink","ff8ac0"},Special={"teal","4ccac0"},Scaling={"gold","f4c84a"}}
local function frame(im,category)
 for y=0,H-1 do for x=0,W-1 do
  if in_round(x,y,0,0,W,H,10) then
   local col
   if not in_round(x,y,2,2,W-4,H-4,9) then col=INK
   elseif not in_round(x,y,3,3,W-6,H-6,8) then col=hex("fffaee")
   else
    col=hex("f1e4c4")
    if (x*3+y*5)%11==0 or (x+y*2)%17==0 then col=hex("e4d4b0") end
    if y>H-10 then col=hex("e0cfa8") end
   end
   im:drawPixel(x,y,col)
  end
 end end
 -- Art window border.
 for y=AY-2,AY+AH+1 do for x=AX-2,AX+AW+1 do
  if in_round(x,y,AX-2,AY-2,AW+4,AH+4,8) and not in_window(x,y) then im:drawPixel(x,y,INK) end
 end end
 -- Footer: category gem between two rules.
 for x=14,W-15 do im:drawPixel(x,170,hex("c8b48c"));im:drawPixel(x,180,hex("c8b48c")) end
 local gem=CATEGORY[category] or CATEGORY.Chaos
 for dy=-5,5 do local w=5-math.abs(dy) for dx=-w,w do im:drawPixel(70+dx,175+dy,INK) end end
 for dy=-4,4 do local w=4-math.abs(dy) for dx=-w,w do im:drawPixel(70+dx,175+dy,hex(gem[2])) end end
 im:drawPixel(69,173,hex("ffffff"));im:drawPixel(70,172,hex("ffffff"))
end

-- Illustrations -------------------------------------------------------------------
local ART={}
ART.kaleidoscope=function(im)
 background(im,R.blue,"rays")
 -- Rainbow beam entering the prism.
 local beam={"ef5a4f","ffd04a","6fcf6a","5cc0f0","b07ee0"}
 for i,c in ipairs(beam) do
  shape(im,function(x,y) return sd_capsule(x,y,AX-4,120+i*3,CX,96+i*1.5,1.6) end,{ramp={c,c},flat=0.5,colour=function() return hex(c) end,outline=false})
 end
 shape(im,function(x,y) return sd_diamond(x,y,CX,94,34,42) end,{thick=6,shadow=true,outline=INK,colour=function(x,y,shade)
  local dx,dy=x+0.5-CX,y+0.5-94
  local ramp=(dx<0 and dy<0) and R.red or (dx>=0 and dy<0) and R.yellow or (dx<0) and R.purple or R.blue
  local face=(dx<0 and dy<0) and 0.85 or (dx>=0 and dy<0) and 0.7 or (dx<0) and 0.45 or 0.3
  if math.abs(dx)/34+math.abs(dy)/42<0.38 then return pick(R.white,0.75,x,y) end
  return pick(ramp,face,x,y)
 end})
 glint(im,{{56,72},{57,71},{58,70},{55,73}});sparkle(im,104,58,3);sparkle(im,30,140,2)
end
ART.mobius=function(im)
 background(im,R.teal,"stars")
 local sdf=function(x,y) return math.min(sd_ring(x,y,48,96,20,7),sd_ring(x,y,92,96,20,7)) end
 shape(im,sdf,{thick=7,shadow=true,ramp=R.orange,colour=function(x,y,shade)
  local a=math.atan(y-96,x-(x<CX and 48 or 92))
  local band=math.floor((a+math.pi)*3)%2==0 and 0.08 or 0
  return pick(R.orange,shade+band,x,y)
 end})
 glint(im,{{36,80},{37,79},{80,80},{81,79}})
end
ART.labyrinth=function(im)
 background(im,R.purple,"grid")
 shape(im,function(x,y) return sd_box(x,y,CX,96,44,44,8) end,{thick=5,shadow=true,ramp=R.bone})
 local walls={{40,62,40,110},{40,62,100,62},{100,62,100,96},{56,78,90,78},{56,78,56,128},{72,94,72,128},{72,94,100,94},{88,110,88,128},{40,128,100,128}}
 for _,w in ipairs(walls) do shape(im,function(x,y) return sd_capsule(x,y,w[1],w[2],w[3],w[4],2.5) end,{thick=2.5,ramp=R.ink}) end
 local path={{48,70},{48,120},{64,120},{64,86},{94,86},{94,120}}
 for i=1,#path-1 do
  local a,b=path[i],path[i+1]
  shape(im,function(x,y) return sd_capsule(x,y,a[1],a[2],b[1],b[2],2) end,{thick=2,ramp=R.red,outline=false})
 end
 shape(im,function(x,y) return sd_circle(x,y,94,120,5) end,{thick=5,ramp=R.red})
 glint(im,{{92,117},{93,117}})
end
ART.tsquare=function(im)
 background(im,R.green,"grid")
 shape(im,function(x,y) return math.min(sd_box(x,y,CX,62,46,9,3),sd_box(x,y,CX,104,9,44,3)) end,{thick=4,shadow=true,ramp=R.wood,colour=function(x,y,shade)
  local v=shade
  if (y%7==0 and math.abs(x+0.5-CX)<9) or (x%7==0 and y<71) then v=v-0.25 end
  return pick(R.wood,v,x,y)
 end})
 for k=0,10 do local x=30+k*8 for dy=0,(k%2==0 and 6 or 3) do im:drawPixel(x,55+dy,hex("3a200e")) end end
 glint(im,{{28,55},{29,55},{30,55}})
end
ART.gravity=function(im)
 background(im,R.night,"stars")
 shape(im,function(x,y) return math.abs(sd_ellipse(x,y,CX,96,50,16))-3.5 end,{thick=3,ramp=R.orange,outline=false})
 shape(im,function(x,y) return sd_circle(x,y,CX,96,24) end,{thick=12,ramp=R.ink,outline=hex("7a4ac0")})
 -- Front half of the ring passes over the hole.
 shape(im,function(x,y) if y<96 then return 9 end return math.abs(sd_ellipse(x,y,CX,96,50,16))-3.5 end,{thick=3,ramp=R.orange,outline=false})
 stamp(im,"candy_0",22,48,0.5);stamp(im,"candy_3",96,128,0.5);stamp(im,"candy_2",100,52,0.5)
end
ART.paintball=function(im)
 background(im,R.green,"dots")
 local blobs={{"pink",44,80,18},{"blue",92,72,15},{"yellow",80,122,17}}
 for _,b in ipairs(blobs) do
  local r=R[b[1]]
  shape(im,function(x,y)
   local d=sd_circle(x,y,b[2],b[3],b[4])
   for k=0,5 do local a=k*1.05+b[2]*0.1 d=smin(d,sd_circle(x,y,b[2]+math.cos(a)*b[4]*1.05,b[3]+math.sin(a)*b[4]*1.05,b[4]*0.32),4) end
   return d
  end,{thick=3,ramp=r})
 end
 shape(im,function(x,y) return sd_circle(x,y,58,112,13) end,{thick=13,shadow=true,ramp=R.white})
 glint(im,{{52,105},{53,104},{54,104}})
end
ART.sledgehammer=function(im)
 background(im,R.green,"rays")
 local a=-0.6
 shape(im,function(x,y) return sd_capsule(x,y,40,140,84,76,5) end,{thick=5,shadow=true,ramp=R.wood})
 shape(im,function(x,y) local rx,ry=rot(x,y,88,70,a) return sd_box(rx,ry,88,70,26,15,5) end,{thick=8,shadow=true,ramp=R.green,colour=function(x,y,shade)
  local rx=rot(x,y,88,70,a)
  local stripe=math.floor((rx-62)/6)%2==0
  return pick(stripe and R.green or R.white,shade,x,y)
 end})
 sparkle(im,30,62,3);sparkle(im,40,50,1);sparkle(im,22,78,1)
end
ART.ricochet=function(im)
 background(im,R.green,"grid")
 local pts={{20,140},{54,60},{82,124},{108,70}}
 for i=1,#pts-1 do
  local a,b=pts[i],pts[i+1]
  shape(im,function(x,y) return sd_capsule(x,y,a[1],a[2],b[1],b[2],2+i*0.6) end,{thick=2,ramp=R.white,flat=0.3+i*0.15,outline=false})
 end
 shape(im,function(x,y) return sd_circle(x,y,108,70,13) end,{thick=13,shadow=true,ramp=R.red})
 glint(im,{{102,63},{103,62},{104,62}})
 for _,p in ipairs({{54,60},{82,124}}) do sparkle(im,p[1],p[2],3) end
end
ART.nuclear=function(im)
 background(im,R.night,"glow")
 shape(im,function(x,y) return sd_circle(x,y,CX,96,36) end,{thick=18,shadow=true,ramp={"2a4a08","4a7a10","7ab81c","b0e030","e0ff70","f8ffd0"}})
 shape(im,function(x,y)
  local dx,dy=x-CX,y-96;local r=len(dx,dy)
  if r<6 then return -1 end
  local a=math.atan(dy,dx)+math.pi/2
  local sector=(math.floor((a+math.pi)/(math.pi/3))%2==0)
  if sector and r>10 and r<30 then return -1 end
  return 1
 end,{flat=0.2,ramp=R.ink,outline=false})
 glint(im,{{54,72},{55,71},{56,70},{53,73}})
end
ART.midas=function(im)
 background(im,R.purple,"rays")
 local sdf=function(x,y)
  local d=sd_box(x,y,CX,112,24,20,9)
  for k=0,3 do d=smin(d,sd_capsule(x,y,52+k*12,100,52+k*12,62+math.abs(k-1.5)*4,6),3) end
  d=smin(d,sd_capsule(x,y,46,116,30,96,6),3)
  return d
 end
 shape(im,sdf,{thick=8,shadow=true,ramp=R.gold})
 sparkle(im,104,56,3);sparkle(im,28,62,2);sparkle(im,108,128,2)
 glint(im,{{50,66},{51,65},{62,62},{63,61}})
end
ART.prism=function(im)
 background(im,R.night,"stars")
 local rb={R.red,R.orange,R.yellow,R.green,R.blue,R.purple}
 shape(im,function(x,y) return sd_diamond(x,y,CX,96,26,48) end,{thick=6,shadow=true,outline=INK,colour=function(x,y,shade)
  local a=math.atan(y+0.5-96,x+0.5-CX)
  local i=math.floor((a+math.pi)/(2*math.pi)*6)%6+1
  return pick(rb[i],shade*0.6+0.25,x,y)
 end})
 glint(im,{{62,70},{63,69},{64,68}});sparkle(im,96,60,3);sparkle(im,40,130,2)
end
ART.necro=function(im)
 background(im,R.purple,"stars")
 shape(im,function(x,y) return sd_ellipse(x,y,CX,100,46,52) end,{thick=6,ramp=R.purple,flat=0.2})
 local sdf=function(x,y) return smin(sd_circle(x,y,CX,90,30),sd_box(x,y,CX,120,18,12,5),6) end
 shape(im,sdf,{thick=10,shadow=true,ramp=R.bone})
 for _,e in ipairs({{57,92},{83,92}}) do shape(im,function(x,y) return sd_ellipse(x,y,e[1],e[2],8,9) end,{flat=0.05,ramp=R.ink,outline=false}) end
 shape(im,function(x,y) return sd_diamond(x,y,CX,107,4,5) end,{flat=0.1,ramp=R.ink,outline=false})
 for k=0,3 do shape(im,function(x,y) return sd_box(x,y,58+k*8,125,1,5,0) end,{flat=0.2,ramp=R.bone,outline=false}) end
 im:drawPixel(55,90,hex("b0e030"));im:drawPixel(81,90,hex("b0e030"))
end
ART.addict=function(im)
 background(im,R.red,"dots")
 shape(im,function(x,y) return sd_capsule(x,y,CX,72,34,46,9) end,{thick=8,ramp=R.red})
 shape(im,function(x,y) return sd_capsule(x,y,CX,72,106,46,9) end,{thick=8,ramp=R.blue})
 shape(im,function(x,y) return sd_circle(x,y,32,44,6) end,{thick=6,ramp=R.yellow})
 shape(im,function(x,y) return sd_circle(x,y,108,44,6) end,{thick=6,ramp=R.yellow})
 shape(im,function(x,y) return sd_circle(x,y,CX,104,30) end,{thick=12,shadow=true,ramp=R.white})
 for _,e in ipairs({{58,98},{82,98}}) do shape(im,function(x,y) return sd_ellipse(x,y,e[1],e[2],4,6) end,{flat=0.1,ramp=R.ink,outline=false}) end
 shape(im,function(x,y) return sd_circle(x,y,CX,108,5) end,{thick=5,ramp=R.red})
 shape(im,function(x,y) local d=math.abs(sd_circle(x,y,CX,108,16))-1.6 if y<114 then return 9 end return d end,{flat=0.1,ramp=R.red,outline=false})
end
ART.roulette=function(im)
 background(im,R.green,"stripes")
 shape(im,function(x,y) return sd_circle(x,y,CX,96,46) end,{thick=6,shadow=true,ramp=R.wood})
 shape(im,function(x,y) return sd_circle(x,y,CX,96,38) end,{thick=12,outline=INK,colour=function(x,y,shade)
  local a=math.atan(y+0.5-96,x+0.5-CX)
  local k=math.floor((a+math.pi)/(math.pi/9))
  local r=len(x+0.5-CX,y+0.5-96)
  if r<16 then return pick(R.gold,shade,x,y) end
  if k==0 then return pick(R.green,shade,x,y) end
  return pick(k%2==0 and R.red or R.ink,shade+(k%2==0 and 0 or 0.25),x,y)
 end})
 shape(im,function(x,y) return sd_circle(x,y,CX,96,6) end,{thick=6,ramp=R.gold})
 shape(im,function(x,y) return sd_circle(x,y,92,70,5) end,{thick=5,ramp=R.white})
 glint(im,{{90,68}})
end
ART.broken=function(im)
 background(im,R.red,"stripes")
 shape(im,function(x,y) return math.min(sd_capsule(x,y,CX,140,CX,70,4),sd_box(x,y,CX,142,22,5,3)) end,{thick=4,shadow=true,ramp=R.gold})
 local a=-0.18
 shape(im,function(x,y) local rx,ry=rot(x,y,CX,68,a) return sd_capsule(rx,ry,26,68,114,68,3.5) end,{thick=3.5,ramp=R.gold})
 for _,p in ipairs({{30,60},{110,76}}) do
  shape(im,function(x,y) if y<p[2]+14 then return 9 end return sd_ellipse(x,y,p[1],p[2]+14,16,9) end,{thick=6,ramp=R.gold})
  shape(im,function(x,y) return sd_capsule(x,y,p[1],p[2],p[1]-12,p[2]+14,1) end,{flat=0.3,ramp=R.ink,outline=false})
  shape(im,function(x,y) return sd_capsule(x,y,p[1],p[2],p[1]+12,p[2]+14,1) end,{flat=0.3,ramp=R.ink,outline=false})
 end
 local crack={{58,58},{64,66},{60,72},{68,80},{64,88}}
 for i=1,#crack-1 do local p,q=crack[i],crack[i+1] shape(im,function(x,y) return sd_capsule(x,y,p[1],p[2],q[1],q[2],1.2) end,{flat=0.05,ramp=R.ink,outline=false}) end
end
ART.ouroboros=function(im)
 background(im,R.red,"rays")
 shape(im,function(x,y) local d=sd_ring(x,y,CX,98,34,10) if x>CX and y<98 and y>58 and x<CX+18 then d=math.max(d,4) end return d end,{thick=9,shadow=true,ramp=R.green,colour=function(x,y,shade)
  local scale=((x+y)%6<2) and 0.12 or 0
  return pick(R.green,shade+scale,x,y)
 end})
 shape(im,function(x,y) return sd_ellipse(x,y,CX+14,62,14,11) end,{thick=8,ramp=R.green})
 shape(im,function(x,y) return sd_circle(x,y,CX+18,58,3) end,{thick=3,ramp=R.yellow})
 im:drawPixel(CX+18,58,INK)
end
-- Supply cards: a container and the candy it supplies.
local function supply(im,ramp_name,container,candy)
 background(im,R.caramel,"dots")
 local ramp=R[ramp_name]
 if container=="basket" then
  shape(im,function(x,y) if y<100 then return 9 end return sd_ellipse(x,y,CX,100,46,34) end,{thick=6,shadow=true,ramp=R.wood,colour=function(x,y,shade)
   local weave=((math.floor(x/6)+math.floor(y/6))%2==0) and 0.1 or -0.08
   return pick(R.wood,shade+weave,x,y)
  end})
  shape(im,function(x,y) return math.abs(sd_ellipse(x,y,CX,100,42,30))-2.5 end,{thick=2,ramp=R.wood,colour=function(x,y,shade) if y>100 then return nil end return pick(R.wood,shade,x,y) end})
 elseif container=="tin" then
  shape(im,function(x,y) return sd_box(x,y,CX,116,40,22,6) end,{thick=8,shadow=true,ramp=R.blue,colour=function(x,y,shade) return pick((math.floor(y/6)%2==0) and R.blue or R.white,shade,x,y) end})
  shape(im,function(x,y) return sd_box(x,y,CX,92,43,6,3) end,{thick=4,ramp=R.steel})
 elseif container=="crate" then
  shape(im,function(x,y) return sd_box(x,y,CX,112,42,26,3) end,{thick=4,shadow=true,ramp=R.wood,colour=function(x,y,shade)
   local plank=(math.floor((y-86)/9)%2==0) and 0.05 or -0.06
   if math.abs((x-28)-(y-86)*1.6)<3 then plank=0.18 end
   return pick(R.wood,shade+plank,x,y)
  end})
 elseif container=="vault" then
  shape(im,function(x,y) return sd_box(x,y,CX,108,44,32,8) end,{thick=6,shadow=true,ramp=R.steel})
  shape(im,function(x,y) return sd_ring(x,y,CX,108,18,4) end,{thick=4,ramp=R.steel})
  for k=0,3 do local a=k*math.pi/2+0.4 shape(im,function(x,y) return sd_capsule(x,y,CX,108,CX+math.cos(a)*16,108+math.sin(a)*16,2.5) end,{thick=2.5,ramp=R.gold}) end
 elseif container=="press" then
  shape(im,function(x,y) return sd_ellipse(x,y,CX,126,44,10) end,{thick=6,shadow=true,ramp=R.white})
  shape(im,function(x,y) if y>124 then return 9 end return sd_diamond(x,y,CX,124,24,30) end,{thick=6,ramp=R.white,colour=function(x,y,shade) return pick(R.white,shade+((x%6<2) and -0.1 or 0),x,y) end})
 else -- patch: a little garden mound with leaves
  shape(im,function(x,y) if y<108 then return 9 end return sd_ellipse(x,y,CX,128,52,22) end,{thick=8,shadow=true,ramp=R.choc})
  for k=0,4 do local lx=34+k*18 shape(im,function(x,y) local rx,ry=rot(x,y,lx,104,0.6*(k%2==0 and 1 or -1)) return sd_ellipse(rx,ry,lx,104,5,11) end,{thick=4,ramp=R.green}) end
 end
 stamp(im,candy,CX-46,44,1);stamp(im,candy,CX-2,52,1)
end
ART.supply_berry=function(im) supply(im,"red","basket","candy_0") end
ART.supply_lemon=function(im) supply(im,"yellow","press","candy_1") end
ART.supply_mint=function(im) supply(im,"green","patch","candy_2") end
ART.supply_peppermint=function(im) supply(im,"blue","tin","candy_3") end
ART.supply_plum=function(im) supply(im,"purple","crate","candy_4") end
ART.supply_caramel=function(im) supply(im,"caramel","vault","candy_5") end
ART.pop_rock=function(im)
 background(im,R.pink,"rays")
 local shards={{CX,90,14,30,0},{CX-22,104,10,20,-0.5},{CX+22,102,10,22,0.5},{CX-8,120,8,14,-0.2},{CX+12,122,8,14,0.3}}
 for i,s in ipairs(shards) do
  shape(im,function(x,y) local rx,ry=rot(x,y,s[1],s[2],s[5]) return sd_diamond(rx,ry,s[1],s[2],s[3],s[4]) end,{thick=4,shadow=i==1,ramp=R.pink,colour=function(x,y,shade)
   local rx=rot(x,y,s[1],s[2],s[5])
   return pick(R.pink,(rx<s[1]) and 0.8 or 0.4,x,y)
  end})
 end
 for _,p in ipairs({{30,56},{110,60},{24,96},{116,104},{40,140},{100,138}}) do sparkle(im,p[1],p[2],2,hex("ffffff")) end
end
ART.sweet_tooth=function(im)
 background(im,R.pink,"dots")
 local sdf=function(x,y)
  local d=sd_box(x,y,CX,84,30,22,12)
  d=smin(d,sd_capsule(x,y,CX-16,96,CX-20,136,9),5)
  d=smin(d,sd_capsule(x,y,CX+16,96,CX+20,136,9),5)
  return d
 end
 shape(im,sdf,{thick=10,shadow=true,ramp=R.white})
 glint(im,{{50,68},{51,67},{52,67},{49,69}});sparkle(im,104,60,3)
 stamp(im,"candy_0",88,112,0.5)
end
ART.golden_trio=function(im)
 background(im,R.pink,"rays")
 for _,p in ipairs({{CX,70},{CX-26,114},{CX+26,114}}) do
  shape(im,function(x,y) return sd_diamond(x,y,p[1],p[2],20,22) end,{thick=6,shadow=true,ramp=R.gold,colour=function(x,y,shade)
   local dx,dy=x+0.5-p[1],y+0.5-p[2]
   local v=(dx<0 and dy<0) and 0.9 or (dx>=0 and dy<0) and 0.65 or (dx<0) and 0.45 or 0.25
   return pick(R.gold,v,x,y)
  end})
 end
 sparkle(im,104,52,3);sparkle(im,30,60,2)
end
ART.three_scoops=function(im)
 background(im,R.pink,"stripes")
 shape(im,function(x,y) if y<104 then return 9 end return ((math.abs(x+0.5-CX)/22)-(146-y)/42)*12 end,{thick=4,shadow=true,ramp=R.caramel,colour=function(x,y,shade)
  local waffle=((x+y)%8<2 or (x-y)%8<2) and -0.2 or 0
  return pick(R.caramel,shade+waffle,x,y)
 end})
 shape(im,function(x,y) return sd_circle(x,y,CX,96,19) end,{thick=12,ramp=R.choc})
 shape(im,function(x,y) return sd_circle(x,y,CX,76,17) end,{thick=12,ramp=R.white})
 shape(im,function(x,y) return sd_circle(x,y,CX,58,15) end,{thick=12,ramp=R.pink})
 shape(im,function(x,y) return sd_circle(x,y,CX+3,42,6) end,{thick=6,ramp=R.red})
 glint(im,{{60,50},{61,49}})
end
ART.striper=function(im)
 background(im,R.teal,"stripes")
 shape(im,function(x,y) return sd_capsule(x,y,36,96,104,96,22) end,{thick=12,shadow=true,ramp=R.red,colour=function(x,y,shade)
  local stripe=math.floor((x+y*0.6)/8)%2==0
  return pick(stripe and R.red or R.white,shade,x,y)
 end})
 for _,s in ipairs({-1,1}) do
  local tip=s<0 and 16 or 124
  shape(im,function(x,y) return sd_diamond(x,y,tip,96,8,10) end,{thick=3,ramp=R.yellow})
 end
 glint(im,{{44,80},{45,79},{46,79},{47,79}})
end
ART.wrapper=function(im)
 background(im,R.teal,"dots")
 local sdf=function(x,y)
  local body=sd_circle(x,y,CX,96,26)
  local fans=math.min(sd_capsule(x,y,18,96,40,96,13),sd_capsule(x,y,100,96,122,96,13))
  return smin(body,fans,4)
 end
 shape(im,sdf,{thick=10,shadow=true,ramp=R.pink,colour=function(x,y,shade)
  if math.abs(x+0.5-CX)>24 then
   local pleat=(math.floor((y+math.abs(x-CX)*0.5)/5)%2==0) and 0.12 or -0.06
   return pick(R.teal,shade+pleat,x,y)
  end
  return pick(R.pink,shade,x,y)
 end})
 glint(im,{{58,80},{59,79},{60,79},{57,81}})
end
ART.bomb_maker=function(im)
 background(im,R.night,"rays")
 shape(im,function(x,y) return sd_circle(x,y,CX,104,42) end,{thick=20,shadow=true,ramp=R.choc})
 local cols={R.red,R.yellow,R.green,R.blue,R.purple,R.white}
 local seed=5
 for i=1,22 do
  seed=(seed*1103515245+12345)%2147483648;local a=(seed%628)/100
  seed=(seed*1103515245+12345)%2147483648;local r=6+(seed%30)
  local x=CX+math.cos(a)*r;local y=104+math.sin(a)*r
  local h=i%2==0
  shape(im,function(px,py) return sd_capsule(px,py,x,y,x+(h and 6 or 0),y+(h and 0 or 6),2.2) end,{thick=2.2,ramp=cols[i%6+1],outline=false,bbox={math.floor(x)-4,math.floor(y)-4,math.floor(x)+9,math.floor(y)+9}})
 end
 shape(im,function(x,y) return sd_capsule(x,y,CX+4,64,CX+16,50,3.5) end,{thick=3.5,ramp=R.wood})
 sparkle(im,CX+18,46,5,hex("ffe98a"))
 glint(im,{{52,84},{53,83},{54,83},{51,85}})
end
ART.sugar_cube=function(im)
 background(im,R.gold,"rays")
 local s=36
 -- Isometric cube: the silhouette is a hexagon; faces are a top diamond and two side panels.
 shape(im,function(x,y)
  local dx,dy=math.abs(x-CX),math.abs(y-98)
  return math.max(dx-s,(dy+dx*0.5-s)*0.9)
 end,{shadow=true,outline=INK,colour=function(x,y,shade)
  local dx,dy=x+0.5-CX,y+0.5-98
  local top=math.abs(dx)/s+math.abs(dy+s*0.5)/(s*0.5)
  local v
  if top<=1 then v=0.92 elseif dx<0 then v=0.66 else v=0.42 end
  -- Edges between faces.
  if math.abs(top-1)<0.06 and dy>-s*0.5 then v=0.12 end
  if math.abs(dx)<0.8 and dy>0 then v=0.12 end
  -- Sugar crystals.
  if (x*7+y*11)%23==0 then v=v-0.18 end
  if (x*5+y*3)%31==0 then v=v+0.1 end
  return pick(R.white,v,x,y)
 end})
 sparkle(im,104,52,3);sparkle(im,32,70,2);sparkle(im,100,140,1)
end
ART.gumball_jar=function(im)
 background(im,R.gold,"dots")
 local cols={R.red,R.blue,R.green,R.purple,R.pink,R.yellow,R.orange,R.red,R.blue}
 local pos={{50,124},{70,128},{90,124},{58,108},{80,108},{96,104},{46,100},{68,92},{88,90}}
 shape(im,function(x,y) return sd_circle(x,y,CX,104,40) end,{thick=4,ramp=R.white,colour=function(x,y,shade) return pick(R.blue,0.82,x,y) end})
 for i,p in ipairs(pos) do shape(im,function(x,y) return sd_circle(x,y,p[1],p[2],9) end,{thick=9,ramp=cols[i]}) end
 shape(im,function(x,y) return math.abs(sd_circle(x,y,CX,104,40))-1.5 end,{flat=0.3,ramp=R.blue,outline=false})
 shape(im,function(x,y) return sd_box(x,y,CX,62,22,7,3) end,{thick=5,shadow=true,ramp=R.red})
 glint(im,{{44,80},{45,79},{43,81},{42,82},{42,83}})
end
ART.candy_cane=function(im)
 background(im,R.gold,"stripes")
 local sdf=function(x,y)
  local stick=sd_capsule(x,y,82,144,82,72,9)
  local hook=sd_ring(x,y,64,72,18,9)
  if y>72 then hook=9 end
  local tip=sd_circle(x,y,46,80,9)
  return math.min(stick,hook,tip)
 end
 shape(im,sdf,{thick=9,shadow=true,ramp=R.red,colour=function(x,y,shade)
  local stripe=math.floor((x*0.8+y)/9)%2==0
  return pick(stripe and R.red or R.white,shade,x,y)
 end})
 sparkle(im,104,60,3);sparkle(im,30,124,2)
end

local CARDS={
 {"joker_0","kaleidoscope","PRISM","Geometry"},{"joker_1","mobius","MOBIUS","Geometry"},{"joker_2","labyrinth","MAZE","Geometry"},
 {"joker_3","tsquare","T-SQUARE","Geometry"},{"joker_4","gravity","GRAVITY","Four"},{"joker_5","paintball","SPLATTER","Four"},
 {"joker_6","sledgehammer","HAMMER","Four"},{"joker_7","ricochet","RICOCHET","Four"},{"joker_8","nuclear","NUCLEAR","Five"},
 {"joker_9","midas","MIDAS","Five"},{"joker_10","prism","WILD","Five"},{"joker_11","necro","NECRO","Five"},
 {"joker_12","addict","ADDICT","Chaos"},{"joker_13","roulette","ROULETTE","Chaos"},{"joker_14","broken","BROKEN","Chaos"},
 {"joker_15","ouroboros","SERPENT","Chaos"},
 {"supply_berry","supply_berry","BASKET","Supply"},{"supply_lemon","supply_lemon","PRESS","Supply"},{"supply_mint","supply_mint","PATCH","Supply"},
 {"supply_peppermint","supply_peppermint","TIN","Supply"},{"supply_plum","supply_plum","CRATE","Supply"},{"supply_caramel","supply_caramel","VAULT","Supply"},
 {"pop_rock","pop_rock","POP ROCK","Three"},{"sweet_tooth","sweet_tooth","TOOTH","Three"},{"golden_trio","golden_trio","GOLDTRIO","Three"},
 {"three_scoops","three_scoops","3 SCOOPS","Three"},{"striper","striper","STRIPER","Special"},{"wrapper","wrapper","WRAPPER","Special"},
 {"bomb_maker","bomb_maker","BOMB","Special"},{"sugar_cube","sugar_cube","CUBE","Scaling"},{"gumball_jar","gumball_jar","GUMBALL","Scaling"},
 {"candy_cane","candy_cane","CANE","Scaling"},
}
local only=app.params["only"]
for _,c in ipairs(CARDS) do
 if not only or only==c[1] then
  local s=Sprite(W,H,ColorMode.RGB);s.layers[1].name="Card stock and frame"
  local stock=s.cels[1].image
  frame(stock,c[4])
  local l=s:newLayer();l.name="Illustration";local art=Image(W,H,ColorMode.RGB);s:newCel(l,1,art)
  local cel=s.cels[#s.cels]
  local im=cel.image
  ART[c[2]](im)
  local t=s:newLayer();t.name="Lettering";local lettering=Image(W,H,ColorMode.RGB);s:newCel(t,1,lettering)
  title(s.cels[#s.cels].image,c[3],INK)
  save=function(sp,name) sp:saveAs(SRC..name..".aseprite");sp:saveCopyAs(OUT..name..".png");sp:close() end
  save(s,c[1])
 end
end
