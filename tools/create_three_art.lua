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
local ids={"pop_rock","sweet_tooth","golden_trio","three_scoops"}
local titles={"POP ROCK","TOOTH","GOLD TRIO","3 SCOOPS"}
local colors={"e7584a","68b5ce","c98654","aa83bb"}
for i=1,4 do
 local s=Sprite(70,94);s.layers[1].name="Printed card stock";local im=s.cels[1].image
 rect(im,0,0,70,94,ink);rect(im,2,2,66,90,c("d8cba4"));rect(im,4,3,62,86,c("f1e4bd"));rect(im,5,20,60,56,ink);rect(im,7,22,56,52,c(colors[i]))
 local art=layer(s,"Hand plotted illustration")
 if i==1 then
  for y=30,62,16 do for x=18,50,16 do outline(art,x-5,y-5,11,11,c("f4c76b"),1) end end
  diamond(art,34,46,17,ink);diamond(art,34,46,14,c("f4c76b"));ellipse(art,34,48,8,9,c("e7584a"));line(art,34,39,39,32,ink);diamond(art,40,30,3,light)
 elseif i==2 then
  ellipse(art,35,42,16,13,ink);rect(art,23,40,25,15,ink);line(art,23,51,27,65,ink);line(art,27,65,35,53,ink);line(art,35,53,43,65,ink);line(art,43,65,48,49,ink)
  ellipse(art,35,41,13,10,light);rect(art,26,41,19,13,light);line(art,26,50,28,60,light);line(art,44,50,42,60,light);diamond(art,52,31,4,c("f4c76b"))
 elseif i==3 then
  for _,p in ipairs({{23,53},{46,53},{35,35}}) do
   diamond(art,p[1],p[2],11,ink);diamond(art,p[1],p[2],9,c("f4c76b"));line(art,p[1]-5,p[2],p[1],p[2]-5,light);line(art,p[1]+1,p[2]+6,p[1]+6,p[2]+1,c("c98654"))
  end
 else
  for y=51,69 do local w=math.floor((70-y)/2);rect(art,35-w,y,w*2+1,1,ink);if w>1 then rect(art,36-w,y,w*2-2,1,c("f4c76b")) end end
  for k=0,2 do ellipse(art,35,48-k*9,12,8,ink);ellipse(art,35,47-k*9,10,6,c(({"75ad70","e7584a","fff1db"})[k+1])) end
  rect(art,29,27,3,2,c("e7584a"));rect(art,39,28,3,2,c("c98654"))
 end
 local print=layer(s,"Lettering and three candy marks")
 title(print,titles[i]);line(print,7,80,62,80,c("b49f77"));line(print,7,89,62,89,c("b49f77"))
 for x=26,42,8 do diamond(print,x,85,2,ink) end
 save(s,ids[i])
end
