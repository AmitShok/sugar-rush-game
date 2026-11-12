-- Special candies: striped/wrapped overlays (56x56), Color Bomb sprite (24x24), and three Joker cards (70x94).
-- Run: Aseprite -b --script-param "root=<project>" --script tools/create_special_art.lua
local root=app.params["root"]
app.fs.makeAllDirectories(root.."/assets/source/aseprite")
app.fs.makeAllDirectories(root.."/assets/exported")
local function c(hex,a) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),a or 255) end
local ink=c("20242c");local light=c("fff1db");local white=c("ffffff")
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
local function tri(im,x,y,dir,size,col)
 -- Solid arrowhead pointing in dir ("l","r","u","d") with its tip at x,y.
 for k=0,size do
  if dir=="r" then rect(im,x-k,y-(size-k),1,(size-k)*2+1,col)
  elseif dir=="l" then rect(im,x+k,y-(size-k),1,(size-k)*2+1,col)
  elseif dir=="d" then rect(im,x-(size-k),y-k,(size-k)*2+1,1,col)
  else rect(im,x-(size-k),y+k,(size-k)*2+1,1,col) end
 end
end
local function layer(s,name)
 local l=s:newLayer();l.name=name;local im=Image(s.width,s.height);local cel=s:newCel(l,1,im);return cel.image
end
local function save(s,name)
 s:saveAs(root.."/assets/source/aseprite/"..name..".aseprite")
 s:saveCopyAs(root.."/assets/exported/"..name..".png");s:close()
end
local function blank(w,h,name)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name=name;return s,s.cels[1].image
end

-- Striped overlays: bright bands across the candy with direction arrows at the tile edge.
for _,dir in ipairs({"h","v"}) do
 local s,shadow=blank(56,56,"Band shadow")
 local bands=layer(s,"Sugar bands")
 local arrows=layer(s,"Direction arrows")
 for k=-1,1 do
  local o=30+k*8
  if dir=="h" then
   rect(shadow,10,o-1,36,4,c("20242c",150));rect(bands,10,o-1,36,2,white);rect(bands,10,o+1,36,1,c("ffd6e6"))
  else
   rect(shadow,o-1,10,4,36,c("20242c",150));rect(bands,o-1,10,2,36,white);rect(bands,o+1,10,1,36,c("ffd6e6"))
  end
 end
 if dir=="h" then
  tri(arrows,1,30,"l",4,ink);tri(arrows,2,30,"l",3,light);tri(arrows,54,30,"r",4,ink);tri(arrows,53,30,"r",3,light)
 else
  tri(arrows,28,2,"u",4,ink);tri(arrows,28,3,"u",3,light);tri(arrows,28,54,"d",4,ink);tri(arrows,28,53,"d",3,light)
 end
 save(s,"ui_striped_"..dir)
end

-- Wrapped overlay: shiny wrapper frame with twisted ends on both sides.
do
 local s,frame=blank(56,56,"Wrapper frame")
 local twists=layer(s,"Twisted ends")
 local shine=layer(s,"Foil shine")
 local pink=c("ff7fb6");local deep=c("b8336f")
 for t=0,2 do
  local col=(t==1) and pink or ink
  rect(frame,11+t,9+t,34-t*2,1,col);rect(frame,11+t,48-t,34-t*2,1,col);rect(frame,11+t,9+t,1,40-t*2,col);rect(frame,44-t,9+t,1,40-t*2,col)
 end
 for _,side in ipairs({-1,1}) do
  local x=(side<0) and 10 or 45
  for k=0,7 do
   local h=8-k
   rect(twists,x+side*k,30-h,1,h*2+1,(k%3==0) and deep or pink)
   rect(twists,x+side*k,30-h-1,1,1,ink);rect(twists,x+side*k,30+h+1,1,1,ink)
  end
  rect(twists,x+side*8,21,1,19,ink)
 end
 line(shine,14,12,20,12,white);line(shine,14,13,16,13,white);rect(shine,40,44,2,2,white)
 save(s,"ui_wrapped")
end

-- Color Bomb: dark chocolate ball covered in six-color sprinkles (displayed at 2x like candies).
do
 local s,body=blank(24,24,"Chocolate ball")
 ellipse(body,12,12,10,10,ink);ellipse(body,12,12,9,9,c("5a3426"));ellipse(body,11,11,7,7,c("6e4130"))
 local sprinkles=layer(s,"Sprinkles")
 local cols={"e7584a","f4c76b","75ad70","68b5ce","aa83bb","c98654"}
 local spots={{7,7},{14,6},{17,11},{9,13},{13,16},{6,15},{16,17},{11,9},{18,14},{10,19}}
 for i,p in ipairs(spots) do rect(sprinkles,p[1],p[2],2,1,c(cols[(i-1)%6+1])) end
 local shine=layer(s,"Shine")
 rect(shine,7,5,3,1,light);rect(shine,6,6,1,2,light)
 save(s,"candy_bomb")
end

-- Joker cards in the shared cream-stock style.
local atlas=Image{fromFile=root.."/assets/exported/font_atlas.png"}
local function title(im,text)
 local left=math.floor((70-#text*7)/2)
 for letter=1,#text do
  local code=string.byte(text,letter)-32
  local ax=(code%16)*16;local ay=math.floor(code/16)*20
  for y=0,10 do for x=0,6 do
   if app.pixelColor.rgbaA(atlas:getPixel(ax+x,ay+y))>0 then rect(im,left+(letter-1)*7+x,5+y,1,1,ink) end
  end end
 end
end
local bomb=Image{fromFile=root.."/assets/exported/candy_bomb.png"}
local berry=Image{fromFile=root.."/assets/exported/candy_0.png"}
local mint=Image{fromFile=root.."/assets/exported/candy_2.png"}
local function stamp(im,src,x,y,scale)
 for yy=0,src.height-1 do for xx=0,src.width-1 do
  local px=src:getPixel(xx,yy)
  if app.pixelColor.rgbaA(px)>0 then rect(im,x+xx*scale,y+yy*scale,scale,scale,px) end
 end end
end
local ids={"striper","wrapper","bomb_maker"}
local titles={"STRIPER","WRAPPER","BOMB"}
local colors={"68b5ce","e7709a","5c4a7a"}
for i=1,3 do
 local s=Sprite(70,94);s.layers[1].name="Printed card stock";local im=s.cels[1].image
 rect(im,0,0,70,94,ink);rect(im,2,2,66,90,c("d8cba4"));rect(im,4,3,62,86,c("f1e4bd"));rect(im,5,20,60,56,ink);rect(im,7,22,56,52,c(colors[i]))
 local art=layer(s,"Hand plotted illustration")
 if i==1 then
  -- Mint gummy at 2x with three sugar bands and sideways arrows.
  stamp(art,mint,17,24,2)
  for k=-1,1 do local y=47+k*9;rect(art,15,y-1,40,4,ink);rect(art,15,y,40,2,white) end
  tri(art,8,47,"l",4,ink);tri(art,9,47,"l",3,light);tri(art,62,47,"r",4,ink);tri(art,61,47,"r",3,light)
 elseif i==2 then
  -- Berry at 2x inside a foil wrapper with twisted ends.
  for y=25,72,6 do for x=10,62,6 do rect(art,x,y,1,1,c("ffffff")) end end
  stamp(art,berry,23,35,1)
  ellipse(art,35,47,13,12,ink);ellipse(art,35,47,12,11,c("ff7fb6"));ellipse(art,33,44,6,5,c("ffb3d2"))
  stamp(art,berry,23,35,1)
  for _,side in ipairs({-1,1}) do
   local x=(side<0) and 22 or 48
   for k=0,12 do local h=math.max(1,11-k);rect(art,x+side*k,47-h,1,h*2+1,(k%3==0) and c("b8336f") or c("ff9cc6"));rect(art,x+side*k,47-h-1,1,1,ink);rect(art,x+side*k,47+h+1,1,1,ink) end
  end
  line(art,29,40,33,38,white)
 else
  -- Color Bomb at 2x with a starburst and a lit fuse.
  for k=0,7 do local a=k*math.pi/4;line(art,35,49,math.floor(35+math.cos(a)*26),math.floor(49+math.sin(a)*24),c("f4c76b")) end
  stamp(art,bomb,11,25,2)
  rect(art,33,24,4,3,ink);line(art,37,24,42,22,c("c98654"));diamond(art,44,22,2,c("f4c76b"))
 end
 local print=layer(s,"Lettering and special marks")
 title(print,titles[i]);line(print,7,80,62,80,c("b49f77"));line(print,7,89,62,89,c("b49f77"))
 diamond(print,35,85,2,ink)
 save(s,ids[i])
end
