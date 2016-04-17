from PIL import Image,ImageDraw,ImageFont

# sample text and font
unicode_text = u" ABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ1234567890πΩ"
verdana_font = ImageFont.truetype("UbuntuMono-R.ttf", 16, encoding="unic")

for i in range(len(unicode_text)):
    # get the line size
    text_width, text_height = verdana_font.getsize(unicode_text[i])
    #print (text_width,text_height)
    import time
    # create a blank canvas with extra space between lines
    canvas = Image.new('RGB', (text_width, text_height), (255, 255, 255))

    # draw the text onto the text canvas, and use black as the text color
    draw = ImageDraw.Draw(canvas)
    draw.fontmode = "1" # Turn off antialiasing, because logic
    draw.text((1,0), unicode_text[i], (0,0,0),font = verdana_font)
    canvas=canvas.crop((0,0,8,16))
    print("-- "+unicode_text[i])
    for y in range(16):
        for x in range(8):
            if x<text_width and y<text_height:
                r,g,b = canvas.getpixel((x, y))

                if r!=0:
                    print("'0',", end='')
                else:
                    print("'1',",end='')
            else:
                print ("'0',", end='')
        print ()

    canvas.save(unicode_text[i]+".png")
