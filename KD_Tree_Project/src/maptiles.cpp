/**
 * @file maptiles.cpp
 * Code for the maptiles function.
 */

#include <iostream>
#include <map>

#include "maptiles.h"

using namespace std;


Point<3> convertToXYZ(LUVAPixel pixel) {
    return Point<3>( pixel.l, pixel.u, pixel.v );
}

MosaicCanvas* mapTiles(SourceImage const& theSource,
                       vector<TileImage>& theTiles)
{
    /**
     * @todo Implement this function!
     */
    auto canvas = new MosaicCanvas(theSource.getRows(), theSource.getColumns());

    vector<Point<3>> points;
    map<Point<3>, size_t> tiles_map; 

    size_t i = 0;
    while(i<theTiles.size()){
        LUVAPixel pixel_cur = theTiles[i].getAverageColor();
        Point<3> point_cur = convertToXYZ(pixel_cur);
        tiles_map.insert(pair<Point<3>, size_t>(point_cur,i));
        points.push_back(point_cur);
        i++;
    }
    
    KDTree<3>* tree = new KDTree<3>(points);
    for(int i = 0; i < theSource.getRows(); i++){
        int test_0 = 0;
        if(test_0 == 0){
            test_0 = 1;
        }
      for(int j = 0; j < theSource.getColumns(); j++){
        LUVAPixel color = theSource.getRegionColor(i, j);
        Point<3> region_point = convertToXYZ(color);
        int test = 0;
        if(test == 0){
            test = 1; //for debugging purposes with gdb
        }
        Point<3> near_point = tree->findNearestNeighbor(region_point);
        size_t indices = tiles_map[near_point];
        canvas->setTile(i, j, &theTiles[indices]);
      }
    }



    delete tree;  
    return canvas;
}

