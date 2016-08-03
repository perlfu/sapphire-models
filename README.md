# Sapphire Models

This repository contains SPIN models of algorithms used in 
the Transactional Sapphire garbage collector [1].

Our implementation of the garbage collector can be found at:
  http://dx.doi.org/10.5281/zenodo.58855


## Contents

- concurrentCopy:
  Models of concurrent copying protocol.  These models check if
  a value of a field of an object can be copied correctly while
  a mutator is writing to the field.  
  
  There are models of two protocols:

   - casCopy.pml: concurrent copying with CAS
   - stmCopy.pml: concurrent copying with with software transactional memory

  Defining NO_FENCE at the first line of each model removes a necessary
  fence causing an assertion violation.

- header:
  Model of handling of the header word, particularly hashcode.
  This model ensures that the hashcode of an object never changes.

- referenceType:
  Checks various properties of reference types in Java.
  See the paper [2] for details.

  Defining DELETION_BARRIER at the first line of the model enables
  a deletion write barrier rather than insertion write barrier.
  

## References

1. Transactional Sapphire: Lessons in High Performance,
   On-the-fly Garbage Collection [in submission]

2. T. Ugawa, R. E. Jones, C. G. Ritson: Reference object processing
   in on-the-fly garbage collection, In Proceedings of the 2014
   international symposium on Memory management (ISMM '14),
   pp. 56--69, (2014).
