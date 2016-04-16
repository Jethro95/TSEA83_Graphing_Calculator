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

                r=int(round((r/255.0)*7))
                g=int(round((g/255.0)*7))
                b=int(round((b/255.0)*3))
                print('x"'+format((int(format(r, '03b')+format(g, '03b')+format(b, '02b'),2)),'02x')+'",', end='')
            else:
                print ('x"ff",', end='')
        print ()

    canvas.save(unicode_text[i]+".png")
