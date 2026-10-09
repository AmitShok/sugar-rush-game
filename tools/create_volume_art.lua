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


local s=Sprite(16,24);s.layers[1].name="Volume slider grip";local im=s.cels[1].image
rect(im,0,0,16,24,ink);rect(im,2,2,12,20,c("f4c76b"));rect(im,3,3,10,2,light)
for x=5,11,3 do rect(im,x,7,1,10,c("855035")) end
save(s,"ui_volume_knob")
