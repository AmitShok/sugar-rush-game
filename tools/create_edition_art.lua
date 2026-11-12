-- Joker editions (70x94 overlays) and the three scaling Joker cards.
-- Run: Aseprite -b --script-param "root=<project>" --script tools/create_edition_art.lua
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
local function frame(im,col,t)
 rect(im,0,0,70,t,col);rect(im,0,94-t,70,t,col);rect(im,0,0,t,94,col);rect(im,70-t,0,t,94,col)
end

-- Foil: cool silver-blue diagonal sheen across the illustration, glinting corners.
do
 local s=Sprite(70,94,ColorMode.RGB);s.layers[1].name="Foil border";local border=s.cels[1].image
 frame(border,c("9fd8f0"),2)
 local sheen=layer(s,"Diagonal sheen")
 for k=-60,60,9 do
  for t=0,2 do line(sheen,7+k+t,22,7+k+t+52,74,c("dff4ff",t==1 and 110 or 60)) end
 end
 rect(sheen,0,22,7,52,c("000000",0));rect(sheen,63,22,7,52,c("000000",0))
 local glint=layer(s,"Glints")
 for _,p in ipairs({{4,4},{65,4},{4,89},{65,89}}) do diamond(glint,p[1],p[2],2,white) end
 save(s,"edition_foil")
end

-- Holographic: pink and violet dot screen with a bright rim.
do
 local s=Sprite(70,94,ColorMode.RGB);s.layers[1].name="Holo border";local border=s.cels[1].image
 frame(border,c("f4a3c0"),2);rect(border,2,2,66,1,c("c9a3f4"));rect(border,2,91,66,1,c("c9a3f4"))
 local dots=layer(s,"Holo dot screen")
 for y=23,73,4 do for x=8,62,4 do
  local col=((x+y)%8==0) and c("f4a3c0",150) or c("c9a3f4",120)
  rect(dots,x+((y/4)%2==0 and 0 or 2),y,1,1,col)
 end end
 save(s,"edition_holo")
end

-- Polychrome: rainbow border in candy colors plus a soft rainbow band.
do
 local s=Sprite(70,94,ColorMode.RGB);s.layers[1].name="Rainbow border";local border=s.cels[1].image
 local cols={"e7584a","f4c76b","75ad70","68b5ce","aa83bb","f4a3c0"}
 local perimeter={}
 for x=0,69 do table.insert(perimeter,{x,0}) end
 for y=1,93 do table.insert(perimeter,{69,y}) end
 for x=68,0,-1 do table.insert(perimeter,{x,93}) end
 for y=92,1,-1 do table.insert(perimeter,{0,y}) end
 for i,p in ipairs(perimeter) do
  local col=c(cols[math.floor((i-1)/12)%6+1])
  rect(border,p[1],p[2],1,1,col)
  rect(border,math.min(68,math.max(1,p[1]+(p[1]==0 and 1 or (p[1]==69 and -1 or 0)))),math.min(92,math.max(1,p[2]+(p[2]==0 and 1 or (p[2]==93 and -1 or 0)))),1,1,col)
 end
 local band=layer(s,"Rainbow band")
 for i,hex in ipairs(cols) do rect(band,7,22+(i-1)*9,56,9,c(hex,45)) end
 save(s,"edition_poly")
end

-- Scaling Joker cards in the shared cream-stock style.
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
local ids={"sugar_cube","gumball_jar","candy_cane"}
local titles={"CUBE","GUMBALL","CANE"}
local colors={"68b5ce","f4c76b","75ad70"}
for i=1,3 do
 local s=Sprite(70,94);s.layers[1].name="Printed card stock";local im=s.cels[1].image
 rect(im,0,0,70,94,ink);rect(im,2,2,66,90,c("d8cba4"));rect(im,4,3,62,86,c("f1e4bd"));rect(im,5,20,60,56,ink);rect(im,7,22,56,52,c(colors[i]))
 local art=layer(s,"Hand plotted illustration")
 if i==1 then
  -- Isometric sugar cube with a growth arrow.
  local top={{35,30},{53,40},{35,50},{17,40}}
  for y=30,50 do for x=17,53 do
   local dx=math.abs(x-35)/18;local dy=math.abs(y-40)/10
   if dx+dy<=1 then rect(art,x,y,1,1,white) end
  end end
  for y=0,20 do
   rect(art,17,40+y,18,1,c("e8e2d4"));rect(art,35,50+y-10,18,1,c("cfc8b8"))
  end
  for y=40,60 do rect(art,17,y,1,1,ink) end
  for y=40,70 do rect(art,53,y-10,1,1,ink) end
  line(art,17,40,35,30,ink);line(art,35,30,53,40,ink);line(art,53,40,35,50,ink);line(art,35,50,17,40,ink);line(art,35,50,35,70,ink);line(art,17,60,35,70,ink);line(art,35,70,53,60,ink)
  for _,p in ipairs({{26,38},{40,36},{31,44},{24,52},{44,54},{30,62},{46,62}}) do rect(art,p[1],p[2],1,1,c("b8b0a0")) end
  line(art,57,64,57,46,ink);diamond(art,57,44,3,ink);diamond(art,57,44,2,c("f4c76b"))
 elseif i==2 then
  -- Glass jar of gumballs.
  rect(art,24,31,22,5,ink);rect(art,25,32,20,3,c("c98654"))
  ellipse(art,35,53,17,18,ink);ellipse(art,35,53,15,16,c("dff4ff"));rect(art,26,35,18,2,ink)
  local cols={"e7584a","68b5ce","75ad70","aa83bb","f4a3c0","e7584a","f4c76b","68b5ce"}
  local spots={{29,62},{37,63},{44,58},{26,55},{34,55},{41,50},{30,47},{38,44}}
  for k,p in ipairs(spots) do ellipse(art,p[1],p[2],3,3,ink);ellipse(art,p[1],p[2],2,2,c(cols[k]));rect(art,p[1]-1,p[2]-1,1,1,white) end
  line(art,24,40,24,58,white);line(art,25,38,26,37,white)
 else
  -- Striped candy cane.
  local path={}
  for t=0,40 do table.insert(path,{40,70-t}) end
  for a=0,20 do local ang=math.pi*a/20;table.insert(path,{math.floor(32+math.cos(ang)*8+0.5),math.floor(30-math.sin(ang)*8+0.5)}) end
  for k,p in ipairs(path) do ellipse(art,p[1],p[2],4,4,ink) end
  for k,p in ipairs(path) do ellipse(art,p[1],p[2],3,3,(math.floor(k/5)%2==0) and c("e7584a") or white) end
  for _,p in ipairs({{15,30},{55,26},{18,64},{54,58}}) do diamond(art,p[1],p[2],2,light) end
 end
 local print=layer(s,"Lettering and growth mark")
 title(print,titles[i]);line(print,7,80,62,80,c("b49f77"));line(print,7,89,62,89,c("b49f77"))
 line(print,30,87,35,82,ink);line(print,35,82,40,87,ink)
 save(s,ids[i])
end
