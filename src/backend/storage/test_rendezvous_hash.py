#!python3

# python implementation of a rendezvous hash distributed hash table.


import mmh3
import math
import random
import pytest
from pytest import fixture

def int_to_float(value: int) -> float:
    """Converts a uniformly random [[64-bit computing|64-bit]] integer to uniformly random floating point number on interval <math>[0, 1)</math>."""
    fifty_three_ones = 0xFFFFFFFFFFFFFFFF >> (64 - 53)
    fifty_three_zeros = float(1 << 53)
    return (value & fifty_three_ones) / fifty_three_zeros

class Node:
    """Class representing a node that is assigned keys as part of a weighted rendezvous hash."""
    def __init__(self, name: str, seed, weight) -> None:
        self.name, self.seed, self.weight = name, seed, weight
        self.table = {}

    def __str__(self):
        return "[" + self.name + " (" + str(self.seed) + ", " + str(self.weight) + ")]"

    def compute_weighted_score(self, key):
        hash_1, hash_2 = mmh3.hash64(str(key), 0xFFFFFFFF & self.seed)
        hash_f = int_to_float(hash_2)
        score = 1.0 / -math.log(hash_f)
        return self.weight * score
    

#complexity: O(klogn)
def get_top_k_nodes(nodes, key, k):
    node_scores=[node.compute_weighted_score(key) for node in nodes]
    # k bubble sort
    try:
        arr=zip(node_scores,nodes)
        for i in range(k):
            for j in range(len(arr) -i - 1):
                if arr[j][0] > arr[j+1][0]:
                    arr[j],arr[j+1] = arr[j+1],arr[j]
        return list(zip(*arr[-k]))[1] # last k elems, of arr, just the second column (nodes)
    except Exception as e:
        raise(e)

def k_bubblesort(arr, k):
    for i in range(k):
        for j in range(len(arr) - i - 1):
            if arr[j] > arr[j+1]:
                arr[j],arr[j+1] = arr[j+1], arr[j]
    return arr[-k:] # last k elements

#implement skeleton variant of rendezvous hash
# class Cluster:
#     def __init__(self, num_nodes, fan_out):
#         for node_num in range(num_nodes):
            


class DistributedHashTable:
    def __init__(self, num_nodes, k_redundancy):
        self.num_nodes=num_nodes
        self.k_redundancy=k_redundancy
        self.nodes=[Node(f"node_{i}",random.randint(0,255),1) for i in range(self.num_nodes)]
        self.offline_nodes=[]
        self.offline_node_indices=[]
    
    #complexity: k*k*logn
    def put(self, key, data):
        nodes = get_top_k_nodes(self.nodes, key, self.k_redundancy)
        for i in range(self.k_redundancy):
            nodes[i].table[key] = data
    
    
    def get(self, key):
        nodes = get_top_k_nodes(self.nodes, key, self.k_redundancy)
        for i,node in enumerate(sorted_nodes):
            val=node.table.get(key,None)
            if val is not None:
                if i>self.k_redundancy-1:
                    self.rebalance(key, sorted_nodes, node)
                return val
        return None
    
    def rebalance(self, key, sorted_nodes, old_node):
        val = old_node.pop(key) #deletes entry
        for i in range(self.k_redundancy):
            sorted_nodes[i].table[key]=val
        
    
    def add_node(self):
        self.num_nodes+=1
        self.nodes.append(Node(f"node_{self.num_nodes}", random.randint(0,255),1))
    
    def remove_node(self, node_index):
        self.num_nodes-=1
        node=self.nodes.pop(node_index)
        #redistribute all the items to the other nodes
        for key,val in node.table.items():
            self.put(key, val)
    
    def take_node_offline(self):
        offline_node_index=random.randint(0,self.num_nodes-1)
        self.offline_node_indices.append(offline_node_index)
        self.offline_nodes.append(self.nodes[offline_node_index].table)
        self.nodes[offline_node_index].table={}
    
    def restore_node(self):
        last_offline_node_index=self.offline_node_indices[-1]
        self.nodes[last_offline_node_index].table=self.offline_nodes[-1]
        self.offline_node_indices.pop()
        self.offline_nodes.pop()



       
def test_rendezvous_hash():
    for i in range(100):
        dwt = DistributedHashTable(5, 3)
        dwt.put("cheese","123")
        dwt.put("potato", "456")
        dwt.put("tomato", "789")

        assert dwt.get("cheese") == "123"
        assert dwt.get("potato") == "456"
        assert dwt.get("tomato") == "789"

        dwt.take_node_offline()
        dwt.take_node_offline()

        assert dwt.get("cheese") == "123"
        assert dwt.get("potato") == "456"
        assert dwt.get("tomato") == "789"

def test_rendezvous_add_node():
    for i in range(100):
        dwt = DistributedHashTable(5, 2)
        dwt.put("cheese","123")
        dwt.put("potato", "456")
        dwt.put("tomato", "789")
        dwt.add_node()
        dwt.put("bread", "aaa")
        dwt.put("egg", "bbb")
        dwt.put("milk", "ccc")

        assert dwt.get("cheese") == "123"
        assert dwt.get("potato") == "456"
        assert dwt.get("tomato") == "789"
        assert dwt.get("bread") == "aaa"
        assert dwt.get("egg") == "bbb"
        assert dwt.get("milk") == "ccc"
    
def test_rendezvous_remove_node():
    for i in range(100):
        dwt = DistributedHashTable(5, 2)
        dwt.put("cheese","123")
        dwt.put("potato", "456")
        dwt.put("tomato", "789")
        dwt.remove_node(1)
        dwt.remove_node(3)
        assert dwt.num_nodes == 3
        assert len(dwt.nodes) == 3
        assert dwt.get("cheese") == "123"
        assert dwt.get("potato") == "456"
        assert dwt.get("tomato") == "789"


def test_k_bubblesort():
    arr=[15, 10, 26, 5, -10, 6]
    result = k_bubblesort(arr, 2)
    assert result == [15, 26]
    

def test_k_reserve_bubblesort():
    arr=[15, 10, 26, 5, -10, 6]
    result = k_bubblesort(arr, 2)
    assert result == [26, 15]