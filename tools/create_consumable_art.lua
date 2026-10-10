local root=app.params["root"]
app.fs.makeAllDirectories(root.."/assets/source/aseprite")
app.fs.makeAllDirectories(root.."/assets/exported")
local function c(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local ink=c("20242c");local light=c("fff1db")
local function rect(im,x,y,w,h,col)
 for yy=math.max(0,y),math.min(im.height-1,y+h-1) do for xx=math.max(0,x),math.min(im.width-1,x+w-1) do im:drawPixel(xx,yy,col) end end
end
local function line(im,x,y,ex,ey,col)
 local steps=math.max(math.abs(ex-x),math.abs(ey-y)); for i=0,steps do local t=steps==0 and 0 or i/steps;rect(im,math.floor(x+(ex-x)*t),math.floor(y+(ey-y)*t),1,1,col) end
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
local ids={"sugar_shaker_card","extra_serving","golden_glaze","candy_hammer"}
local titles={"SHAKER","SECONDS","GLAZE","HAMMER"}
local colors={"68b5ce","75ad70","c98654","aa83bb"}
for i=1,4 do
 local s=Sprite(70,94);s.layers[1].name="Printed card stock";local im=s.cels[1].image
 rect(im,0,0,70,94,ink);rect(im,2,2,66,90,c("d8cba4"));rect(im,4,3,62,86,c("f1e4bd"));rect(im,5,20,60,56,ink);rect(im,7,22,56,52,c(colors[i]))
 local art=layer(s,"Consumable illustration")
 if i==1 then
  local jar=Image{fromFile=root.."/assets/exported/sugar_shaker.png"};art:drawImage(jar,Point(19,28))
 elseif i==2 then
  ellipse(art,34,60,22,9,ink);ellipse(art,34,58,19,7,light)
  ellipse(art,27,46,9,9,ink);ellipse(art,27,45,7,7,c("e7584a"));ellipse(art,43,46,9,9,ink);ellipse(art,43,45,7,7,c("f4c76b"));rect(art,52,28,3,27,ink);ellipse(art,53,27,5,7,ink);ellipse(art,53,26,3,5,light)
 elseif i==3 then
  rect(art,15,38,23,27,ink);rect(art,18,41,17,20,c("f4c76b"));rect(art,13,34,27,6,ink);rect(art,15,35,23,3,light)
  line(art,43,29,49,43,ink);line(art,45,29,51,43,ink);ellipse(art,48,45,6,8,c("f4c76b"));diamond(art,49,65,4,c("f4c76b"));diamond(art,23,50,4,light)
 else
  line(art,27,65,43,36,ink);line(art,30,65,46,36,ink);line(art,28,64,44,36,c("c98654"))
  rect(art,29,27,28,14,ink);rect(art,31,29,24,10,c("fff1db"));rect(art,32,37,22,2,c("68b5ce"));diamond(art,20,57,6,c("e7584a"));line(art,14,49,9,45,light);line(art,21,46,21,40,light);line(art,12,59,8,60,light)
 end
 local print=layer(s,"Lettering and single-use marks")
 title(print,titles[i]);line(print,7,80,62,80,c("b49f77"));diamond(print,34,85,3,ink)
 save(s,ids[i])
end
