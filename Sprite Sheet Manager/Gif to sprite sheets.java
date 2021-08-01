/*
 * Gif to image sequence code by Chris Stillwell https://stackoverflow.com/a/10627458
 * Gif delay code by Sage https://stackoverflow.com/a/20079110
 * 
 * This will convert the gif provided in the hard coded path below into sprite sheets.
 * Files are named 1.png, 2.png, ... and the program will overwrite any images by the same name.
 */

import java.io.*;
import java.awt.Image;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.event.*;
import java.net.*;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import org.w3c.dom.Node;
import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.metadata.IIOMetadata;
import javax.imageio.stream.ImageInputStream;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.NodeList;
import javax.imageio.metadata.IIOMetadataNode;

public class gifToSpriteSheet{
    // Path to the gif file. Can be a file path or a url. Not all gifs work.
    static String gifPath = "https://cdn.discordapp.com/emojis/423966409232744449.gif?v=1";
    //static String gifPath = "C:\\Users\\JaCoB\\Desktop\\Stuff\\Pics\\worley noise.gif";
    // Output directory of sprite set.
    static String outDir = "sprite sheet\\";
    // Set clearOnRedraw to true if the gif has transparency.
    static boolean clearOnRedraw = false;

    public static void main(String[] args) throws Exception {
        new File(outDir).mkdirs();
        /*for(File f: new File(outDir).listFiles())
            if(f.getName().endsWith(".png"))
                f.delete();*/

        int sheetIndex = 1;
        int width = 0;
        int height = 0;
        int rows = 0;
        int columns = 0;
        int spriteSheetMaxWidth = 1024;
        int spriteSheetMaxHeight = 1024;
        int spriteSheetWidth = 0;
        int spriteSheetHeight = 0;
        int x = 0, y = 0;
        int spritesLeft = 0;
        BufferedImage curSheet = null;
        Graphics g = null;
        Graphics2D g2 = null;

        String[] imageatt = new String[]{
                "imageLeftPosition",
                "imageTopPosition",
                "imageWidth",
                "imageHeight"
            };    

        ImageReader reader = (ImageReader)ImageIO.getImageReadersByFormatName("gif").next();
        ImageInputStream ciis = null;
        if(new File(gifPath).exists()){
            ciis = ImageIO.createImageInputStream(new File(gifPath));
        }else{
            ciis = ImageIO.createImageInputStream(new URL(gifPath).openStream());
        }
        reader.setInput(ciis, false);

        int noi = reader.getNumImages(true);

        System.out.println("Delay: " + getDelay(gifPath));
        System.out.println("Sprites: " + noi);

        BufferedImage master = null;

        for (int i = 0; i < noi; i++) { 
            BufferedImage image = reader.read(i);
            IIOMetadata metadata = reader.getImageMetadata(i);

            Node tree = (Node) metadata.getAsTree("javax_imageio_gif_image_1.0");
            NodeList children = tree.getChildNodes();

            for (int j = 0; j < children.getLength(); j++) {
                Node nodeItem = (Node) children.item(j);

                if(nodeItem.getNodeName().equals("ImageDescriptor")){
                    Map<String, Integer> imageAttr = new HashMap<String, Integer>();

                    for (int k = 0; k < imageatt.length; k++) {
                        NamedNodeMap attr = nodeItem.getAttributes();
                        Node attnode = (Node) attr.getNamedItem(imageatt[k]);
                        imageAttr.put(imageatt[k], Integer.valueOf(attnode.getNodeValue()));
                    }
                    if(i==0){
                        width = imageAttr.get("imageWidth");
                        height = imageAttr.get("imageHeight");

                        System.out.println("Sprite dim: " + width + " x " + height);
                        columns = spriteSheetMaxWidth / width;
                        rows = spriteSheetMaxHeight / height;
                        System.out.println("Columns: " + columns + "\nRows: " + rows);
                        spriteSheetWidth = columns * width;
                        spriteSheetHeight = rows * height;
                        System.out.println("Sheet dim: " + spriteSheetWidth + " x " + spriteSheetHeight);
                        System.out.println("Sheet count: " + (int)Math.ceil(noi / (double)(columns * rows)));
                        System.out.println("Sprites per sheet: " + (columns * rows));
                        int last = noi % (columns * rows);
                        System.out.println("Sprites on last sheet: " + (last == 0 ? (columns * rows) : last));

                        spritesLeft = columns * rows;
                        curSheet = new BufferedImage(spriteSheetWidth, spriteSheetHeight, BufferedImage.TYPE_INT_ARGB);
                        g = curSheet.getGraphics();

                        master = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
                        g2 = (Graphics2D)master.getGraphics();
                        g2.setBackground(new Color(0,0,0,0));
                    }
                    if(clearOnRedraw)
                        g2.clearRect(0, 0, width, height);
                    g2.drawImage(image, imageAttr.get("imageLeftPosition"), imageAttr.get("imageTopPosition"), null);
                }
            }

            // Draw to sheet
            if(spritesLeft == 0){
                new File(outDir + sheetIndex + ".png").delete();
                ImageIO.write(curSheet, "png", new File(outDir + sheetIndex + ".png"));
                sheetIndex++;
                spritesLeft = columns * rows;
                curSheet = new BufferedImage(spriteSheetWidth, spriteSheetHeight, BufferedImage.TYPE_INT_ARGB);
                g = curSheet.getGraphics();
                x = 0;
                y = 0;
            }
            g.drawImage(master, x, y, null);
            x += width;
            if(x >= spriteSheetWidth){
                x = 0;
                y += height;
            }
            spritesLeft--;
        }
        new File(outDir + sheetIndex + ".png").delete();
        ImageIO.write(curSheet, "png", new File(outDir + sheetIndex + ".png"));
        
        System.out.println("Done");
    }

    private static double getDelay(String path) throws Exception {
        ImageReader reader = ImageIO.getImageReadersBySuffix("gif").next();
        if(new File(path).exists()){
            reader.setInput(ImageIO.createImageInputStream(new FileInputStream(path)));
        }else{
            reader.setInput(ImageIO.createImageInputStream(new URL(path).openStream()));
        }
        int i = reader.getMinIndex();
        int numImages = reader.getNumImages(true);

        IIOMetadata imageMetaData =  reader.getImageMetadata(0);
        String metaFormatName = imageMetaData.getNativeMetadataFormatName();

        IIOMetadataNode root = (IIOMetadataNode)imageMetaData.getAsTree(metaFormatName);

        IIOMetadataNode graphicsControlExtensionNode = getNode(root, "GraphicControlExtension");

        return Double.valueOf(graphicsControlExtensionNode.getAttribute("delayTime")) * 0.01;
    }

    private static IIOMetadataNode getNode(IIOMetadataNode rootNode, String nodeName) {
        int nNodes = rootNode.getLength();
        for (int i = 0; i < nNodes; i++) {
            if (rootNode.item(i).getNodeName().compareToIgnoreCase(nodeName)== 0) {
                return((IIOMetadataNode) rootNode.item(i));
            }
        }
        IIOMetadataNode node = new IIOMetadataNode(nodeName);
        rootNode.appendChild(node);
        return(node);
    }
}
