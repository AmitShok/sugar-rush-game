-- Candy-shop art revision (v0.24). Supersedes the candy drawings in create_art.lua and the panels,
-- board tiles, particle and table in create_ui_art.lua: run this script AFTER those if you regenerate everything.
-- Run: Aseprite -b --script-param "root=<project>" --script tools/create_v2_art.lua
local root=app.params["root"]
app.fs.makeAllDirectories(root.."/assets/source/aseprite")
app.fs.makeAllDirectories(root.."/assets/exported")
local function c(hex,a) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),a or 255) end
local ink=c("1c1022");local white=c("ffffff")
local function rect(im,x,y,w,h,col)
 for yy=math.max(0,y),math.min(im.height-1,y+h-1) do for xx=math.max(0,x),math.min(im.width-1,x+w-1) do im:drawPixel(xx,yy,col) end end
end
local function line(im,x,y,ex,ey,col)
 local steps=math.max(math.abs(ex-x),math.abs(ey-y)); for i=0,steps do local t=steps==0 and 0 or i/steps;rect(im,math.floor(x+(ex-x)*t+0.5),math.floor(y+(ey-y)*t+0.5),1,1,col) end
end
local function ellipse(im,x,y,rx,ry,col)
 for yy=-ry,ry do for xx=-rx,rx do if xx*xx/(rx*rx)+yy*yy/(ry*ry)<=1 then rect(im,x+xx,y+yy,1,1,col) end end end
end
local function diamond(im,x,y,r,col)
 for yy=-r,r do local w=r-math.abs(yy);rect(im,x-w,y+yy,w*2+1,1,col) end
end
local function layer(s,name)
 local l=s:newLayer();l.name=name;local im=Image(s.width,s.height);local cel=s:newCel(l,1,im);return cel.image
end
local function save(s,name)
 s:saveAs(root.."/assets/source/aseprite/"..name..".aseprite")
 s:saveCopyAs(root.."/assets/exported/"..name..".png");s:close()
end
local function outline(im,x,y,w,h,col,t)
 rect(im,x,y,w,t,col);rect(im,x,y+h-t,w,t,col);rect(im,x,y,t,h,col);rect(im,x+w-t,y,t,h,col)
end

-- Candies ---------------------------------------------------------------------
-- Four tones per candy (light, base, shade, deep) plus a white glint and a soft shadow.
local tones={
 {"ff9a86","ef5a4f","c23a43","8e2238"}, -- Berry Bonbon
 {"fff0a0","ffd04a","e09a26","a8661a"}, -- Lemon Drop
 {"b8f0a0","6fcf6a","3e9a52","24683c"}, -- Mint Gummy
 {"c8f0ff","5cc0f0","2e86c8","1d5590"}, -- Blue Peppermint
 {"e8c4ff","b07ee0","7c50b4","52307e"}, -- Plum Jellybean
 {"ffd9a0","e0a05a","b06c34","7a4422"}, -- Caramel Square
}
for k=0,5 do
 local t=tones[k+1];local L,B,S,D=c(t[1]),c(t[2]),c(t[3]),c(t[4])
 local s=Sprite(24,24,ColorMode.RGB);s.layers[1].name="Soft shadow";local shadow=s.cels[1].image
 local body=layer(s,"Body and shading")
 local shine=layer(s,"Glint")
 if k==0 then
  -- Wrapped bonbon: twisted wrapper ends and a round glossy center.
  ellipse(shadow,13,14,9,8,c("000000",70))
  for _,side in ipairs({-1,1}) do
   local x=side<0 and 1 or 18
   rect(body,x,6,5,12,ink);rect(body,x+1,7,3,10,S);rect(body,x+1,7,3,3,L);line(body,x+1,12,x+3,12,D)
  end
  ellipse(body,12,12,8,8,ink);ellipse(body,12,12,7,7,D);ellipse(body,12,11,7,6,S);ellipse(body,11,10,6,5,B);ellipse(body,10,9,3,2,L)
  rect(shine,8,7,3,1,white);rect(shine,7,8,1,2,white);rect(shine,15,15,1,1,L)
 elseif k==1 then
  -- Lemon drop: faceted diamond.
  diamond(shadow,13,13,11,c("000000",70))
  diamond(body,12,12,11,ink);diamond(body,12,12,10,D);diamond(body,12,11,9,S);diamond(body,11,10,8,B);diamond(body,10,9,4,L)
  line(body,12,20,20,12,D);line(shine,6,10,10,6,white);rect(shine,9,8,1,1,white)
 elseif k==2 then
  -- Gummy bear.
  ellipse(shadow,13,14,9,9,c("000000",70))
  ellipse(body,7,5,4,4,ink);ellipse(body,17,5,4,4,ink);ellipse(body,12,10,8,7,ink)
  rect(body,5,11,15,11,ink);rect(body,3,12,19,6,ink)
  ellipse(body,7,5,3,3,S);ellipse(body,17,5,3,3,S);ellipse(body,7,5,2,2,B);ellipse(body,17,5,2,2,B)
  ellipse(body,12,10,7,6,S);ellipse(body,12,9,6,5,B)
  rect(body,6,12,13,9,S);rect(body,4,13,17,4,S);rect(body,7,12,11,7,B);rect(body,8,13,4,3,L)
  rect(body,6,20,4,2,D);rect(body,15,20,4,2,D)
  rect(body,9,9,2,2,ink);rect(body,14,9,2,2,ink);rect(body,11,11,3,1,D)
  rect(shine,9,6,2,1,white);rect(shine,8,14,1,2,white)
 elseif k==3 then
  -- Peppermint swirl.
  ellipse(shadow,13,13,10,10,c("000000",70))
  ellipse(body,12,12,10,10,ink);ellipse(body,12,12,9,9,c("e8eef8"));ellipse(body,12,11,8,8,white)
  for a=0,5 do
   local ang=a*math.pi/3
   for r=1,8 do
    local px=math.floor(12+math.cos(ang+r*0.25)*r+0.5);local py=math.floor(12+math.sin(ang+r*0.25)*r+0.5)
    if a%2==0 then rect(body,px,py,2,1,B) end
   end
  end
  ellipse(body,12,12,2,2,S);rect(body,4,15,2,3,c("c8d4e8"))
  rect(shine,7,6,3,1,white);rect(shine,6,7,1,2,white)
 elseif k==4 then
  -- Jellybean, tilted.
  ellipse(shadow,13,14,9,8,c("000000",70))
  ellipse(body,14,9,7,6,ink);ellipse(body,9,15,7,6,ink);rect(body,6,8,12,11,ink)
  ellipse(body,14,9,6,5,S);ellipse(body,9,15,6,5,S);rect(body,7,9,10,9,S)
  ellipse(body,13,8,5,4,B);ellipse(body,9,14,5,4,B);rect(body,8,9,7,7,B)
  rect(body,12,15,5,2,D);ellipse(body,12,8,2,1,L)
  rect(shine,10,6,3,1,white);rect(shine,6,12,1,3,white)
 else
  -- Caramel square with four glossy pillows.
  rect(shadow,4,5,19,18,c("000000",70))
  rect(body,3,3,18,18,ink);rect(body,2,5,20,14,ink);rect(body,4,4,16,16,D)
  for yy=5,13,8 do for xx=5,13,8 do
   rect(body,xx,yy,6,6,S);rect(body,xx,yy,5,5,B);rect(body,xx,yy,5,1,L);rect(body,xx,yy,1,4,L);rect(body,xx+5,yy+1,1,5,D)
  end end
  rect(shine,6,6,2,1,white);rect(shine,14,6,2,1,white)
 end
 save(s,"candy_"..k)
end

-- Color Bomb redraw to match the new candy shading.
do
 local s=Sprite(24,24,ColorMode.RGB);s.layers[1].name="Soft shadow";local shadow=s.cels[1].image
 ellipse(shadow,13,13,10,10,c("000000",70))
 local body=layer(s,"Chocolate ball")
 ellipse(body,12,12,10,10,ink);ellipse(body,12,12,9,9,c("3a2018"));ellipse(body,12,11,8,8,c("5a3426"));ellipse(body,11,10,6,6,c("74462f"))
 local sprinkles=layer(s,"Sprinkles")
 local cols={"ef5a4f","ffd04a","6fcf6a","5cc0f0","b07ee0","ff9cc6"}
 local spots={{7,7},{14,6},{17,11},{9,13},{13,16},{6,15},{16,17},{11,9},{18,14},{10,19},{15,13}}
 for i,p in ipairs(spots) do rect(sprinkles,p[1],p[2],2,1,c(cols[(i-1)%6+1])) end
 local shine=layer(s,"Glint")
 rect(shine,7,5,3,1,white);rect(shine,6,6,1,2,white)
 save(s,"candy_bomb")
end

-- Board tiles: mid plum with a soft bevel so candies pop.
for _,name in ipairs({"tile_a","tile_b"}) do
 local s=Sprite(56,56,ColorMode.RGB);s.layers[1].name="Tile";local im=s.cels[1].image
 local fill=name=="tile_a" and "4a3158" or "553a64"
 rect(im,1,1,54,54,c("2e1c36"));rect(im,2,2,52,52,c(fill))
 local bevel=layer(s,"Bevel")
 rect(bevel,3,2,50,1,c("7a5a8c"));rect(bevel,2,3,1,50,c("6a4c7a"))
 rect(bevel,3,53,50,1,c("38243f"));rect(bevel,53,3,1,50,c("3c2744"))
 save(s,"ui_"..name)
end

-- Panels and buttons: beveled nine-slice skins with a top highlight and drop edge.
local function panel(name,fill,edge,highlight,dark)
 local s=Sprite(24,24,ColorMode.RGB);s.layers[1].name="Beveled pixel border"
 local im=s.cels[1].image
 rect(im,3,0,18,24,c(edge));rect(im,0,3,24,18,c(edge));rect(im,1,2,22,20,c(edge));rect(im,2,1,20,22,c(edge))
 local face=layer(s,"Flat center - nine slice")
 rect(face,3,2,18,20,c(fill));rect(face,2,3,20,18,c(fill))
 local finish=layer(s,"Gloss and drop edge")
 rect(finish,3,2,18,1,c(highlight));rect(finish,3,22,18,1,c(dark));rect(finish,2,21,20,1,c(dark,120))
 save(s,name)
end
panel("ui_panel","3b2742","8a5f8f","5a3d63","241628")
panel("ui_inset","24162a","6c4a72","33203a","160c1a")
panel("ui_disabled","3a3040","5d5266","463b4d","2a222f")
panel("ui_boss","5c2a4a","d67aa5","7a3a62","3a1a2e")
panel("ui_progress_gold","f0b43c","ffe29a","ffd770","b07a1c")
panel("ui_green","35a06e","9be3b5","58c48e","1f6a46")
panel("ui_blue","2f86d6","8fd0ff","56a8ec","1c5a96")
-- Default button (berry pink) and its hover/pressed states.
panel("ui_button","d2486e","ff8fae","e86a8c","8e2a48")
panel("ui_button_hover","e45c82","fff3e6","f48aa6","9a3050")
panel("ui_button_pressed","a8385a","ffb3c8","c0466c","6a1e36")
-- Role buttons: go, info, buy, skip, danger, neutral.
local roles={
 go={"35a06e","9be3b5","58c48e","1f6a46"},
 info={"2f86d6","8fd0ff","56a8ec","1c5a96"},
 buy={"c98418","ffd27a","e6a032","7e5010"},
 skip={"8a5aa8","d4b0f4","a87ac6","56366e"},
 danger={"c0394f","ff8a9a","d85a6c","7a1e30"},
 neutral={"5a4466","a88ab6","715580","38283f"},
}
for role,t in pairs(roles) do
 panel("ui_btn_"..role,t[1],t[2],t[3],t[4])
 panel("ui_btn_"..role.."_hover",t[3],"fff3e6",t[2],t[1])
 panel("ui_btn_"..role.."_pressed",t[4],t[2],t[1],t[4])
end

-- Particle: a white four-point sparkle (tinted at runtime).
do
 local s=Sprite(32,32,ColorMode.RGB);s.layers[1].name="Sparkle";local im=s.cels[1].image
 diamond(im,16,16,6,white);rect(im,15,2,3,28,white);rect(im,2,15,28,3,white)
 save(s,"ui_particle")
end
-- Idle glint drawn briefly over resting candies.
do
 local s=Sprite(16,16,ColorMode.RGB);s.layers[1].name="Glint";local im=s.cels[1].image
 rect(im,7,0,2,16,c("ffffff",230));rect(im,0,7,16,2,c("ffffff",230));diamond(im,8,8,3,white)
 save(s,"ui_glint")
end

-- Backdrop: berry-chocolate base painted once, plus a seamless drifting pattern tile.
do
 local s=Sprite(576,360,ColorMode.RGB);s.layers[1].name="Berry chocolate base";local im=s.cels[1].image
 for y=0,359 do for x=0,575 do
  local t=y/359
  local wave=math.sin(x*0.01+y*0.013)*2
  local r=math.floor(46-t*14+wave);local g=math.floor(26-t*8+wave*0.5);local b=math.floor(52-t*14+wave)
  im:drawPixel(x,y,app.pixelColor.rgba(r,g,b,255))
 end end
 local vignette=layer(s,"Vignette")
 for y=0,359 do for x=0,575 do
  local dx=(x-288)/288;local dy=(y-180)/180;local d=dx*dx+dy*dy
  if d>0.55 then vignette:drawPixel(x,y,app.pixelColor.rgba(10,4,14,math.min(150,math.floor((d-0.55)*190)))) end
 end end
 save(s,"table_felt")
end
do
 local s=Sprite(96,96,ColorMode.RGB);s.layers[1].name="Candy stripes";local im=s.cels[1].image
 for k=0,95 do
  for w=0,5 do
   local x=(k+w)%96;local y=k
   im:drawPixel(x,y,c("ff8fbe",11))
   im:drawPixel((x+48)%96,y,c("ffd27a",8))
  end
 end
 local sprinkles=layer(s,"Sprinkles")
 local cols={"ff7fae","ffd04a","8fe39a","8fd0ff","d4b0f4","ffffff"}
 local seed=7
 for i=1,22 do
  seed=(seed*1103515245+12345)%2147483648
  local x=seed%92;seed=(seed*1103515245+12345)%2147483648
  local y=seed%92;local col=c(cols[i%6+1],110)
  if i%2==0 then rect(sprinkles,x,y,3,1,col) else rect(sprinkles,x,y,1,3,col) end
 end
 save(s,"backdrop_tile")
end
