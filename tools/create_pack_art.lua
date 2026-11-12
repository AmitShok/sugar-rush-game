-- Booster pack art (70x94 foil bags) and the Jumbo banner overlay.
-- Run: Aseprite -b --script-param "root=<project>" --script tools/create_pack_art.lua
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
local function layer(s,name)
 local l=s:newLayer();l.name=name;local im=Image(s.width,s.height);local cel=s:newCel(l,1,im);return cel.image
end
local function save(s,name)
 s:saveAs(root.."/assets/source/aseprite/"..name..".aseprite")
 s:saveCopyAs(root.."/assets/exported/"..name..".png");s:close()
end
local atlas=Image{fromFile=root.."/assets/exported/font_atlas.png"}
local function text(im,str,top,col)
 local left=math.floor((70-#str*7)/2)
 for letter=1,#str do
  local code=string.byte(str,letter)-32
  local ax=(code%16)*16;local ay=math.floor(code/16)*20
  for y=0,10 do for x=0,6 do
   if app.pixelColor.rgbaA(atlas:getPixel(ax+x,ay+y))>0 then rect(im,left+(letter-1)*7+x,top+y,1,1,col) end
  end end
 end
end
local function stamp(im,src,x,y,scale)
 for yy=0,src.height-1 do for xx=0,src.width-1 do
  local px=src:getPixel(xx,yy)
  if app.pixelColor.rgbaA(px)>0 then rect(im,x+xx*scale,y+yy*scale,scale,scale,px) end
 end end
end
-- A crimped foil bag: zig-zag top and bottom seals, body color, diagonal shine.
local function bag(s,body,dark)
 local im=s.cels[1].image
 rect(im,3,8,64,78,ink);rect(im,4,9,62,76,c(body))
 for x=3,66,4 do
  rect(im,x,4,3,5,ink);rect(im,x+1,5,1,4,c(dark))
  rect(im,x,85,3,5,ink);rect(im,x+1,85,1,4,c(dark))
 end
 rect(im,4,9,62,3,c(dark));rect(im,4,82,62,3,c(dark))
 local shine=layer(s,"Foil shine")
 for k=0,2 do line(shine,8+k,14,20+k,78,c("ffffff",70)) end
 line(shine,58,16,62,26,c("ffffff",120))
 return shine
end
local packs={
 {"pack_joker","JOKERS","e7584a","a8372d"},
 {"pack_recipe","RECIPES","75ad70","4f7d4b"},
 {"pack_candy","CANDY","68b5ce","3f7f96"},
 {"pack_treat","TREATS","aa83bb","76588a"},
 {"pack_rush","RUSH!","5c4a7a","3b2f52"},
}
for _,p in ipairs(packs) do
 local s=Sprite(70,94,ColorMode.RGB);s.layers[1].name="Foil bag"
 bag(s,p[3],p[4])
 local label=layer(s,"Label and art")
 rect(label,8,18,54,15,ink);rect(label,9,19,52,13,light)
 text(label,p[2],20,ink)
 if p[1]=="pack_joker" then
  -- Two fanned Joker cards with a jester face.
  for k=0,1 do rect(label,14+k*16,38+k*4,26,36,ink);rect(label,15+k*16,39+k*4,24,34,c("f1e4bd")) end
  ellipse(label,43,58,7,7,ink);ellipse(label,43,58,6,6,white);rect(label,40,56,2,2,ink);rect(label,45,56,2,2,ink);rect(label,42,60,3,1,c("e7584a"))
  rect(label,37,47,12,4,ink);rect(label,38,48,4,2,c("e7584a"));rect(label,44,48,4,2,c("68b5ce"))
 elseif p[1]=="pack_recipe" then
  rect(label,16,38,38,36,ink);rect(label,17,39,36,34,c("f1e4bd"))
  for k=0,3 do line(label,21,45+k*7,48,45+k*7,c("b49f77")) end
  diamond(label,22,45,2,c("e7584a"));diamond(label,22,52,2,c("f4c76b"));diamond(label,22,59,2,c("68b5ce"))
 elseif p[1]=="pack_candy" then
  stamp(label,Image{fromFile=root.."/assets/exported/candy_0.png"},12,40,1)
  stamp(label,Image{fromFile=root.."/assets/exported/candy_2.png"},34,40,1)
  stamp(label,Image{fromFile=root.."/assets/exported/candy_5.png"},23,54,1)
 elseif p[1]=="pack_treat" then
  -- Gift box of treats.
  rect(label,15,46,40,28,ink);rect(label,16,47,38,26,c("f4a3c0"))
  rect(label,13,40,44,8,ink);rect(label,14,41,42,6,c("ffb3d2"))
  rect(label,33,40,4,34,c("f4c76b"))
  ellipse(label,29,37,5,3,ink);ellipse(label,41,37,5,3,ink);ellipse(label,29,37,4,2,c("f4c76b"));ellipse(label,41,37,4,2,c("f4c76b"))
 else
  for k=0,7 do local a=k*math.pi/4;line(label,35,56,math.floor(35+math.cos(a)*22),math.floor(56+math.sin(a)*20),c("f4c76b")) end
  diamond(label,35,56,11,ink);diamond(label,35,56,9,c("f4c76b"));diamond(label,35,56,4,white)
 end
 save(s,p[1])
end
-- Jumbo banner overlay, drawn over any pack.
do
 local s=Sprite(70,94,ColorMode.RGB);s.layers[1].name="Jumbo banner";local im=s.cels[1].image
 rect(im,0,70,70,15,ink);rect(im,1,71,68,13,c("f4c76b"))
 text(im,"JUMBO",72,ink)
 save(s,"pack_jumbo")
end
