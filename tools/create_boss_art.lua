-- Boss icons (32x32) for the route preview and boss obstacles/marks (56x56 tile overlays).
-- Run: Aseprite -b --script-param "root=<project>" --script tools/create_boss_art.lua
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
local function layer(s,name)
 local l=s:newLayer();l.name=name;local im=Image(s.width,s.height);local cel=s:newCel(l,1,im);return cel.image
end
local function save(s,name)
 s:saveAs(root.."/assets/source/aseprite/"..name..".aseprite")
 s:saveCopyAs(root.."/assets/exported/"..name..".png");s:close()
end
local function sprite(w,h,name)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name=name;return s,s.cels[1].image
end

-- 56x56 tile overlays ---------------------------------------------------------
-- Chocolate: a full chocolate block with segment grooves.
do
 local s,base=sprite(56,56,"Chocolate block")
 rect(base,5,5,46,46,ink);rect(base,6,6,44,44,c("5a3426"));rect(base,7,7,42,42,c("6e4130"))
 local grooves=layer(s,"Segments")
 for k=0,2 do
  rect(grooves,7+k*14+13,7,1,42,c("4a2a1f"));rect(grooves,7,7+k*14+13,42,1,c("4a2a1f"))
 end
 for y=0,2 do for x=0,2 do rect(grooves,9+x*14,9+y*14,9,1,c("8a5a42")) end end
 save(s,"ui_chocolate")
end
-- Frosting: one or two layers of piped icing over the cell.
for layers=1,2 do
 local s,base=sprite(56,56,"Icing")
 local icing=layers==2 and c("f7d9e8") or c("fbeef5")
 rect(base,5,5,46,46,ink);rect(base,6,6,44,44,icing)
 local piping=layer(s,"Piping")
 for k=0,5 do ellipse(piping,10+k*7,10,3,3,white);ellipse(piping,10+k*7,46,3,3,white) end
 if layers==2 then
  for k=0,3 do line(piping,10,18+k*8,46,18+k*8,c("e7a3c4")) end
  for k=0,2 do ellipse(piping,16+k*12,28,2,2,c("e7709a")) end
 else
  line(piping,12,28,44,28,c("efc2d8"))
 end
 save(s,"ui_frost_"..layers)
end
-- Jelly: translucent pink cell edge with glossy corners (the candy stays visible).
do
 local s,base=sprite(56,56,"Jelly edge")
 for t=0,4 do
  local a=230-t*45
  rect(base,2+t,2+t,52-t*2,1,c("ff7fc0",a));rect(base,2+t,53-t,52-t*2,1,c("ff7fc0",a))
  rect(base,2+t,2+t,1,52-t*2,c("ff7fc0",a));rect(base,53-t,2+t,1,52-t*2,c("ff7fc0",a))
 end
 local gloss=layer(s,"Gloss")
 rect(gloss,5,5,6,2,c("ffffff",180));rect(gloss,5,7,2,3,c("ffffff",180))
 save(s,"ui_mark_jelly")
end
-- Sour mark: a small green drop in the corner of sour candies.
do
 local s,base=sprite(56,56,"Sour drop")
 ellipse(base,46,46,6,6,ink);ellipse(base,46,46,5,5,c("9bd14f"));rect(base,44,36,4,5,ink);rect(base,45,37,2,4,c("9bd14f"))
 local face=layer(s,"Sour face")
 rect(face,43,45,1,1,ink);rect(face,48,45,1,1,ink);line(face,43,49,48,49,ink)
 save(s,"ui_mark_sour")
end

-- 32x32 boss icons ------------------------------------------------------------
local function icon(name,draw)
 local s,base=sprite(32,32,"Icon")
 draw(base,layer(s,"Detail"))
 save(s,"ui_"..name)
end
icon("chocolatier",function(b,d)
 rect(b,6,8,20,18,ink);rect(b,7,9,18,16,c("6e4130"))
 rect(d,15,9,1,16,c("4a2a1f"));rect(d,7,17,18,1,c("4a2a1f"))
 rect(d,9,11,4,1,c("8a5a42"));rect(d,18,11,4,1,c("8a5a42"));rect(d,9,19,4,1,c("8a5a42"));rect(d,18,19,4,1,c("8a5a42"))
 rect(d,24,5,4,4,ink);rect(d,25,6,2,2,c("6e4130"))
end)
icon("frost",function(b,d)
 rect(b,5,10,22,16,ink);rect(b,6,11,20,14,c("fbeef5"))
 for k=0,3 do ellipse(d,8+k*5,10,2,2,white) end
 line(d,16,3,16,29,c("68b5ce"));line(d,4,16,28,16,c("68b5ce"));line(d,8,8,24,24,c("68b5ce"));line(d,24,8,8,24,c("68b5ce"))
end)
icon("sour",function(b,d)
 ellipse(b,16,18,10,10,ink);ellipse(b,16,18,9,9,c("9bd14f"));rect(b,14,4,4,6,ink);rect(b,15,5,2,5,c("9bd14f"))
 rect(d,12,16,2,2,ink);rect(d,19,16,2,2,ink);line(d,12,23,20,23,ink);line(d,11,13,14,14,ink);line(d,21,13,18,14,ink)
end)
icon("spoon",function(b,d)
 ellipse(b,16,10,6,7,ink);ellipse(b,16,10,5,6,c("cfd6dc"))
 rect(b,15,16,3,13,ink);rect(b,16,17,1,11,c("cfd6dc"))
 rect(d,13,7,2,2,white);line(d,22,22,28,22,c("e7584a"));line(d,22,25,28,25,c("e7584a"))
end)
icon("jelly",function(b,d)
 rect(b,6,12,20,16,ink);rect(b,7,13,18,14,c("ff7fb6"))
 ellipse(b,16,12,10,4,ink);ellipse(b,16,12,9,3,c("ff9cc6"))
 rect(d,9,15,3,2,c("ffffff",200));rect(d,9,17,1,3,c("ffffff",200))
end)
icon("tax",function(b,d)
 ellipse(b,16,16,11,11,ink);ellipse(b,16,16,10,10,c("f4c76b"));ellipse(b,16,16,7,7,c("e0a94a"))
 rect(d,15,9,2,14,ink);rect(d,12,11,8,2,ink);rect(d,12,15,8,2,ink);rect(d,12,19,8,2,ink)
 line(d,24,4,28,8,c("e7584a"));line(d,28,4,24,8,c("e7584a"))
end)
icon("hurry",function(b,d)
 ellipse(b,16,17,11,11,ink);ellipse(b,16,17,10,10,light)
 rect(b,13,3,6,3,ink)
 line(d,16,17,16,9,ink);line(d,16,17,22,20,c("e7584a"))
 line(d,2,12,6,12,c("68b5ce"));line(d,1,17,5,17,c("68b5ce"));line(d,2,22,6,22,c("68b5ce"))
end)
