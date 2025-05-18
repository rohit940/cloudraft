#!/bin/bash

for i in $(seq 0 20)
do 
  { time curl -s http://localhost:8080/counter; } 2>&1 | tee -a result.log
done
