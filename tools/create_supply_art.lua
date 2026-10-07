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

-- An open cage keeps the candy underneath visible at all times.
local s=Sprite(56,56);s.layers[1].name="Open blocker frame";local im=s.cels[1].image
outline(im,4,4,48,48,c("20242c"),4);outline(im,5,5,46,46,c("d3a477"),2)
for _,x in ipairs({7,45}) do for _,y in ipairs({7,45}) do rect(im,x,y,4,4,c("fff1db")) end end
local finish=layer(s,"Corner rivets")
save(s,"ui_blocker")
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
local ids={"supply_berry","supply_lemon","supply_mint","supply_peppermint","supply_plum","supply_caramel"}
local titles={"BASKET","PRESS","PATCH","TIN","CRATE","VAULT"}
local palette={"e7584a","f4c76b","75ad70","68b5ce","aa83bb","c98654"}
for i=1,6 do
 local s=Sprite(70,94);s.layers[1].name="Printed card stock";local im=s.cels[1].image
 rect(im,0,0,70,94,ink);rect(im,2,2,66,90,c("d8cba4"));rect(im,4,3,62,86,c("f1e4bd"));rect(im,5,20,60,56,ink);rect(im,7,22,56,52,c(palette[i]))
 local art=layer(s,"Supply illustration")
 if i==1 then
  rect(art,13,44,44,25,ink);rect(art,16,46,38,20,c("c98654"));for x=18,54,6 do line(art,x,47,x,65,c("855035")) end
  for y=50,63,6 do line(art,16,y,53,y,c("f4c76b")) end
 elseif i==2 then
  rect(art,16,27,5,42,ink);rect(art,16,27,37,5,ink);rect(art,31,29,4,14,ink);rect(art,24,40,20,4,ink);rect(art,14,67,44,4,ink)
 elseif i==3 then
  rect(art,12,58,46,12,c("855035"));for x=17,54,9 do line(art,x,61,x-3,46,c("20242c"));line(art,x-3,48,x-8,44,c("fff1db")) end
 elseif i==4 then
  rect(art,16,27,40,43,ink);rect(art,19,30,34,37,c("fff1db"));rect(art,16,26,40,5,c("3d749c"));rect(art,21,63,30,3,c("3d749c"))
 elseif i==5 then
  rect(art,12,32,47,38,ink);rect(art,15,35,41,32,c("c98654"));for y=36,66,10 do line(art,15,y,55,y,c("855035")) end
  line(art,15,35,55,66,c("fff1db"));line(art,55,35,15,66,c("fff1db"))
 else
  rect(art,13,27,46,44,ink);rect(art,16,30,40,38,c("65797b"));outline(art,20,33,31,31,c("fff1db"),2);rect(art,48,44,5,9,ink)
 end
 local candy=Image{fromFile=root.."/assets/exported/candy_"..(i-1)..".png"}
 art:drawImage(candy,Point(23,37))
 local print=layer(s,"Lettering and supply marks")
 title(print,titles[i]);line(print,7,80,62,80,c("b49f77"));line(print,7,87,62,87,c("b49f77"))
 for x=28,42,7 do rect(print,x,83,3,2,ink) end
 save(s,ids[i])
end
