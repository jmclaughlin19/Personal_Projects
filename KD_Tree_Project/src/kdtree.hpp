/**
 * @file kdtree.cpp
 * Implementation of KDTree class.
 */

#include <utility>
#include <algorithm>
#include <deque>
#include <vector>

using namespace std;

template <int Dim>
bool smallerDimVal(const Point<Dim>& first,
                                const Point<Dim>& second, int curDim)
{
    /**
     * @todo Implement this function!
     */

    if(first[curDim] < second[curDim]){
      return true;
    } else if(first[curDim] == second[curDim]){
      return (first<second);
    }

    return false;
}

template <int Dim>
bool shouldReplace(const Point<Dim>& target,
                                const Point<Dim>& currentBest,
                                const Point<Dim>& potential)
{
    /**
     * @todo Implement this function!
     */

    int pot_target_distance = 0;
    int curBest_target_distance = 0;
    
    for(int i=0; i<Dim; i++){
      pot_target_distance = pot_target_distance + ((potential[i] - target[i])*(potential[i]-target[i]));
      curBest_target_distance = curBest_target_distance + ((currentBest[i] - target[i])*(currentBest[i] - target[i]));
    }

    if(pot_target_distance < curBest_target_distance){
      return true;
    }

    if(pot_target_distance == curBest_target_distance){
      return (potential<currentBest);
    }


     return false;
}

template <int Dim>
KDTree<Dim>::KDTree(const vector<Point<Dim>>& newPoints)
{
    /**
     * @todo Implement this function!
     */


    if(newPoints.empty() == true){
      size = 0;
      root = NULL;
    } else{
      size = 0;
      for(size_t i=0; i<newPoints.size(); i++){
        points_vec.push_back(newPoints[i]);
      }
      //Need to construct tree here somehow
      root = TreeMake(0,points_vec.size()-1,0);
    }


}


template <int Dim>
KDTree<Dim>::KDTree(const KDTree<Dim>& other) {
  /**
   * @todo Implement this function!
   */

  copy_helper(root,other->root);

}

template <int Dim>
const KDTree<Dim>& KDTree<Dim>::operator=(const KDTree<Dim>& rhs) {
  /**
   * @todo Implement this function!
   */

  delete_helper(root);
  copy_helper(root,rhs->root);

  return *this;
}

template <int Dim>
KDTree<Dim>::~KDTree() {
  /**
   * @todo Implement this function!
   */

  delete_helper(root);
}

template <int Dim>
Point<Dim> KDTree<Dim>::findNearestNeighbor(const Point<Dim>& query) const
{
    /**
     * @todo Implement this function!
     */

    return neighbor_helper(root, query,0);
}

template <typename RandIter, typename Comparator>
void select(RandIter start, RandIter end, RandIter k, Comparator cmp)
{
    /**
     * @todo Implement this function!
     */    
    
    if(start >= end){
      return;
    }
    int debug = 1;

    RandIter index = start + (distance(start,end) / 2);
    cout << __LINE__ <<  endl;
    index = partition(start,end,k,cmp);

    if(k == index){
      return;
    } else if (k<index){
      if(debug == 1){
        debug = 0;
      }
      return select(start, end-1, k, cmp);
    } else {
      return select(start+1,end,k,cmp);
    }

}


// Helper Functions:


template <typename RandIter, typename Comparator>
RandIter partition(RandIter begin, RandIter end, RandIter pivot_point, Comparator cmp){
  swap(*(end-1),*pivot_point);
  RandIter index = begin;
  int debug = 0;

  for(RandIter iter = begin; iter != end-1; iter++){
    if(debug == 0){
      debug = 1;
    }
    if(cmp(*iter,*(end-1))){
      swap(*(index),*iter);
      index++;
    }
  }
  
  cout << __LINE__ << endl;
  swap(*(end-1),*index);
  return index;

}





template <int Dim>
typename KDTree<Dim>::KDTreeNode * KDTree<Dim>::TreeMake(int left, int right, int dimension) {
  if(right<left){
    return NULL;
  }

  int find_median = (left+right)/2;
  auto cmp = [dimension](auto first, auto second){
    return smallerDimVal(first,second,dimension);
    };

    
  
  select(points_vec.begin()+left,points_vec.begin()+right,points_vec.begin()+find_median,cmp);
  KDTreeNode* sub = new KDTreeNode(points_vec[find_median]);
  cout << __LINE__ << endl;
  sub->left = TreeMake(left,find_median-1, (dimension+1) % Dim);
  sub->right = TreeMake(find_median+1,right,(dimension+1) % Dim);
  return sub;
}



template <int Dim>
void KDTree<Dim>::copy_helper(KDTreeNode*& cur, KDTreeNode*& other){
  if(other == NULL){
    return;
  }

  cur = new KDTreeNode(other->point);
  copy_helper(cur->left,other->left);
  copy_helper(cur->right,other->right);
}


template <int Dim>
void KDTree<Dim>::delete_helper(KDTreeNode*& subroot){
  if(subroot == NULL){
    return;
  }
  delete_helper(subroot->left);
  delete_helper(subroot->right);
  delete subroot;
}

template <int Dim>
Point<Dim> KDTree<Dim>::neighbor_helper(KDTreeNode * subroot, const Point<Dim>& query, int dimension) const{
  bool flag;
  
  Point<Dim> cur_best = subroot->point;
	
	if (subroot->left == NULL ){
    if(subroot->right == NULL){
      return subroot->point;
    }
    
  }
  // cout<< __LINE__<<endl;
	if (smallerDimVal(query, subroot->point, dimension)) {
		if (subroot->left == NULL) 
			cur_best = neighbor_helper(subroot->right, query, (dimension + 1) % Dim);
		else 
			cur_best = neighbor_helper(subroot->left, query, (dimension + 1) % Dim);
		flag = true;  
    int checker = 0;
    if(checker == 0){
      checker = 1; //This is just to debug using gdb so I can see if it is reaching this point
    }
	}

	else {
		if (subroot->right == NULL)  
			cur_best = neighbor_helper(subroot->left, query, (dimension + 1) % Dim);
		else  
			cur_best = neighbor_helper(subroot->right, query, (dimension + 1) % Dim);
		flag = false;  
	}
	// 
	if (shouldReplace(query, cur_best, subroot->point)){
    cur_best = subroot->point;
  } 
	

  float radius = 0;
  int debug = 0;
	
  int i = 0;
  while(i<Dim){
    radius = radius + (query[i] - cur_best[i]) * (query[i] - cur_best[i]);
    i++;
  }
	float dist = subroot->point[dimension] - query[dimension];
	dist = dist * dist;

  if(debug == 0){   //All of these lines just help with gdb through and debugging to test certain values
    debug = 1;
  }


	if (dist <= radius) {
		KDTreeNode * need_to_check = flag ? subroot->right : subroot->left;
		if (need_to_check != NULL) {  
			Point<Dim> otherBest = neighbor_helper(need_to_check, query, (dimension + 1) % Dim);
			if (shouldReplace(query, cur_best, otherBest)){
        cur_best = otherBest;
      } 
      if(debug == 1){ //Checking if code reaches this point
        debug = 0;
      }
		}
	}
	return cur_best;
}
