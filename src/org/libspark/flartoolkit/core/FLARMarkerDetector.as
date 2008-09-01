/* 
 * PROJECT: FLARToolKit
 * --------------------------------------------------------------------------------
 * This work is based on the NyARToolKit developed by
 *   R.Iizuka (nyatla)
 * http://nyatla.jp/nyatoolkit/
 *
 * The FLARToolKit is ActionScript 3.0 version ARToolkit class library.
 * Copyright (C)2008 Saqoosha
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this framework; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 * 
 * For further information please contact.
 *	http://www.libspark.org/wiki/saqoosha/FLARToolKit
 *	<saq(at)saqoosha.net>
 * 
 */

package org.libspark.flartoolkit.core {
	
	import org.libspark.flartoolkit.FLARException;
	import org.libspark.flartoolkit.core.raster.FLARBitmapData;
	
	import flash.display.BitmapData;
	

	/**
	 * イメージからマーカー情報を検出するクラス。
	 * このクラスは、arDetectMarker2.cとの置き換えになります。
	 * ラベリング済みのラスタデータからマーカー位置を検出して、結果を保持します。
	 *
	 */
	public class FLARMarkerDetector {
		
	    private static const AR_AREA_MAX:int = 100000;
	    private static const AR_AREA_MIN:int = 70;
	
	    private var width:int;
	    private var height:int;
	    /**
	     * 最大i_squre_max個のマーカーを検出するクラスを作成する。
	     * @param i_width
	     * @param i_height
	     */
	    public function FLARMarkerDetector(i_width:int, i_height:int) {
			this.width =i_width;
			this.height=i_height;
	    }
	    
	    private static const AR_CHAIN_MAX:int = 10000;
	    private const wk_arGetContour_xdir:Array = [0,  1, 1, 1, 0,-1,-1,-1];
	    private const wk_arGetContour_ydir:Array = [-1,-1, 0, 1, 1, 1, 0,-1];
	    private const wk_arGetContour_xcoord:Array = new Array(AR_CHAIN_MAX);
	    private const wk_arGetContour_ycoord:Array = new Array(AR_CHAIN_MAX);
	    /**
	     * int arGetContour(ARInt16 *limage, int *label_ref,int label, int clip[4], ARMarkerInfo2 *marker_info2)
	     * 関数の代替品
	     * detectMarker関数から使う関数です。o_markerにlabelとclipで示される1個のマーカーを格納します。
	     * marker_holder[i_holder_num]にオブジェクトが無ければまず新規に作成し、もし
	     * 既に存在すればそこにマーカー情報を上書きして記録します。
	     * Optimize:STEP[369->336]
	     * @param o_marker
	     * @param limage
	     * @param label_ref
	     * @param label
	     * @param clip
	     * @throws FLARException
	     */
	    private function arGetContour(o_marker:FLARMarker, limage:BitmapData, i_labelnum:int, i_label:FLARLabel):void {
			var xcoord:Array = wk_arGetContour_xcoord;
			var ycoord:Array = wk_arGetContour_ycoord;
			var xdir:Array = wk_arGetContour_xdir;
			var ydir:Array = wk_arGetContour_ydir;
			var coord_num:int;
			var sx:int = 0, sy:int = 0, dir:int;
			var dmax:int, d:int, v1:int = 0;
			var i: int, j:int, w:int;
		
//			var limage_j:Array;
			j = i_label.clip2;
//			limage_j = limage[j];
			const clip1:int = i_label.clip1;
			//p1=ShortPointer.wrap(limage,j*xsize+clip.get());//p1 = &(limage[j*xsize+clip[0]]);
			for (i = i_label.clip0; i <= clip1; i++) {//for (i = clip[0]; i <= clip[1]; i++, p1++) {
//			    w = limage_j[i];
//			    if (w > 0 && label_ref[w-1] == i_labelnum) {//if (*p1 > 0 && label_ref[(*p1)-1] == label) {
				if (limage.getPixel(i, j) == i_labelnum) {
					sx = i;
					sy = j;
					break;
			    }
			}
			if (i > clip1) {//if (i > clip[1]) {
			    trace("??? 1");//printf();
			    throw new FLARException();//return(-1);
			}
		
		//	//マーカーホルダが既に確保済みかを調べる
		//	if (marker_holder[i_holder_num]==null) {
		//	    //確保していなければ確保
		//	    marker_holder[i_holder_num]=new FLARMarker();
		//	}
		
		
			coord_num = 1;//marker_info2->coord_num = 1;
			xcoord[0] = sx;//marker_info2->x_coord[0] = sx;
			ycoord[0] = sy;//marker_info2->y_coord[0] = sy;
			dir = 5;
			
			var r:int, c:int;
	        c = xcoord[0];
	        r = ycoord[0];
	        dmax = 0;
	        //本家はdmaxの作成とxcoordの作成を別のループでやってるけど、非効率なので統合
			for (;;) {
			    //xcoord[1]-xcoord[n]までのデータを作る。
			    
		//	    1個前のxcoordとycoordはループ後半で格納される。
		//	    c=xcoord[coord_num-1];
		//	    r=ycoord[coord_num-1];
			    //p1 = &(limage[marker_info2->y_coord[marker_info2->coord_num-1] * xsize+ marker_info2->x_coord[marker_info2->coord_num-1]]);
			    dir = (dir+5)%8;
			    for (i = 0; i < 8; i++) {
					//if (limage[r+ydir[dir]][c+xdir[dir]]>0) {//if (p1[ydir[dir]*xsize+xdir[dir]] > 0) {
					if (limage.getPixel(c + xdir[dir], r + ydir[dir]) > 0) { 
					    break;
					}
					dir = (dir + 1) % 8;	
			    }
			    if (i == 8) {
					trace("??? 2");//printf("??? 2\n");
					throw new FLARException();//return(-1);
			    }
		//	    xcoordとycoordをc,rにも保存
			    c = c + xdir[dir];//marker_info2->x_coord[marker_info2->coord_num]= marker_info2->x_coord[marker_info2->coord_num-1] + xdir[dir];
			    r = r + ydir[dir];//marker_info2->y_coord[marker_info2->coord_num]= marker_info2->y_coord[marker_info2->coord_num-1] + ydir[dir];
			    xcoord[coord_num] = c;//marker_info2->x_coord[marker_info2->coord_num]= marker_info2->x_coord[marker_info2->coord_num-1] + xdir[dir];
			    ycoord[coord_num] = r;//marker_info2->y_coord[marker_info2->coord_num]= marker_info2->y_coord[marker_info2->coord_num-1] + ydir[dir];
			    if (c == sx && r == sy) {
					break;
			    }
			    //dmaxの計算
			    d = (c-sx)*(c-sx)+(r-sy)*(r-sy);
			    if (d > dmax) {
					dmax = d;
					v1 = coord_num;
			    }
			    //終了条件判定
			    coord_num++;
			    if (coord_num == AR_CHAIN_MAX-1) {//if (marker_info2.coord_num == Config.AR_CHAIN_MAX-1) {
					trace("??? 3");//printf("??? 3\n");
					throw new FLARException();//return(-1);
			    }
			}
		//
		//	dmax = 0;
		//	for (i=1;i<coord_num;i++) {//	for (i=1;i<marker_info2->coord_num;i++) {
		//	    d = (xcoord[i]-sx)*(xcoord[i]-sx)+ (ycoord[i]-sy)*(ycoord[i]-sy);//	  d = (marker_info2->x_coord[i]-sx)*(marker_info2->x_coord[i]-sx)+ (marker_info2->y_coord[i]-sy)*(marker_info2->y_coord[i]-sy);
		//	    if (d > dmax) {
		//		dmax = d;
		//		v1 = i;
		//	    }
		//	}
			//FLARMarkerへcoord情報をセット
			//coordの並び替えと保存はFLARMarkerへ移動
			o_marker.setCoordXY(v1, coord_num, xcoord, ycoord);
			return;
	    }
	
	    /**
	     * ARMarkerInfo2 *arDetectMarker2(ARInt16 *limage, int label_num, int *label_ref,int *warea, double *wpos, int *wclip,int area_max, int area_min, double factor, int *marker_num)
	     * 関数の代替品
	     * ラベリング情報からマーカー一覧を作成してo_marker_listを更新します。
	     * 関数はo_marker_listに重なりを除外したマーカーリストを作成します。
	     * 
	     * @param i_labeling
	     * ラベリング済みの情報を持つラベリングオブジェクト
	     * @param i_factor
	     * 何かの閾値？
	     * @param o_marker_list
	     * 抽出したマーカーを格納するリスト
	     * @throws FLARException
	     */
	    public function detectMarker(i_labeling:FLARLabeling, i_factor:Number, o_marker_list:FLARMarkerList):void {
	    	var label_area:int;
	    	var i:int;
	    	var xsize:int, ysize:int;
	    	var labels:Array = i_labeling.getLabel();
			var label_num:int = i_labeling.getLabelNum();
			var label_img:BitmapData = i_labeling.getLabelImg();
		
			//マーカーホルダをリセット
			o_marker_list.reset();
			//	marker_num=0;
			xsize = width;
			ysize = height;
			//	マーカーをmarker_holderに蓄積する。
			var current_marker:FLARMarker = o_marker_list.getCurrentHolder();
			var label_pt:FLARLabel;
			for (i = 0; i < label_num; i++) {
			    label_pt = labels[i];
			    label_area = label_pt.area;
			    if (label_area < AR_AREA_MIN || label_area > AR_AREA_MAX) {
					continue;
			    }
			    if (label_pt.clip0 == 1 || label_pt.clip1 == xsize-2) {//if (wclip[i*4+0] == 1 || wclip[i*4+1] == xsize-2) {
					continue;
			    }
			    if (label_pt.clip2 == 1 || label_pt.clip3 == ysize-2) {//if (wclip[i*4+2] == 1 || wclip[i*4+3] == ysize-2) {
					continue;
			    }
			    arGetContour(current_marker, label_img, i+1, label_pt);
		
			    if (!current_marker.checkSquare(label_area, i_factor, label_pt.pos_x, label_pt.pos_y)) {
					//後半で整理するからここはいらない。//        	marker_holder[marker_num2]=null;
					continue;
			    }
		//	    この3行はcheckSquareの最終段に含める。
		//	    marker_holder[marker_num2].area   = warea[i];
		//	    marker_holder[marker_num2].pos[0] = wpos[i*2+0];
		//	    marker_holder[marker_num2].pos[1] = wpos[i*2+1];
			    //マーカー検出→次のホルダを取得
			    current_marker = o_marker_list.getNextHolder();
			    //マーカーリストが上限に達したか確認
			    if (current_marker == null) {
					break;
			    }
			}
			//マーカーリストを整理(重なり処理とかはマーカーリストに責務押し付け)
			o_marker_list.updateMarkerArray();
			return;
	    }
	
	}

}