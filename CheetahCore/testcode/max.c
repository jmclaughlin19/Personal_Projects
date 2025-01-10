#include <stdio.h>

void max( int arr[], int n ) 
{
    int sum = 0;
    int max = arr[0];

    for ( int i = 0; i < n; i++ )
    {
        if ( arr[i] >= max )
            max = arr[i];
    }

    return;
}

int main() 
{
    int arr[] = {3, 1};
    int arr_size = 2;
    max( arr, arr_size );

    return 0;
}