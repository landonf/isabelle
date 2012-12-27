#     Title:      HOL/Tools/Sledgehammer/MaSh/src/theoryModels.py
#     Author:     Daniel Kuehlwein, ICIS, Radboud University Nijmegen
#     Copyright   2012
#
# An updatable sparse naive Bayes classifier.

'''
Created on Dec 26, 2012

@author: Daniel Kuehlwein
'''

from singleNaiveBayes import singleNBClassifier
from cPickle import load,dump
import sys,logging

class TheoryModels(object):
    '''
    MetaClass for all the theory models.
    '''


    def __init__(self):
        '''
        Constructor
        '''
        self.theoryModels = {}
        self.theoryDict = {}
        self.accessibleTheories = []
        self.currentTheory = None
  
    def init(self,depFile,dicts):      
        logger = logging.getLogger('TheoryModels')
        IS = open(depFile,'r')
        for line in IS:
            line = line.split(':')
            name = line[0]
            theory = name.split('.')[0]
            # Name Id
            if not dicts.nameIdDict.has_key(name):
                logger.warning('%s is missing in nameIdDict. Aborting.',name)
                sys.exit(-1)
    
            nameId = dicts.nameIdDict[name]
            features = dicts.featureDict[nameId]
            if not self.theoryDict.has_key(theory):
                assert not theory == self.currentTheory
                if not self.currentTheory == None:
                    self.accessibleTheories.append(self.currentTheory)
                self.currentTheory = theory
                self.theoryDict[theory] = set([nameId])
                theoryModel = singleNBClassifier()
                self.theoryModels[theory] = theoryModel 
            else:
                self.theoryDict[theory] = self.theoryDict[theory].union([nameId])               
            
            # Find the actually used theories
            usedtheories = []    
            dependencies = line[1].split()
            if len(dependencies) == 0:
                continue
            for dep in dependencies:
                depId = dicts.nameIdDict[dep.strip()]
                deptheory = dep.split('.')[0]
                usedtheories.append(deptheory)
                if not self.theoryDict.has_key(deptheory):
                    self.theoryDict[deptheory] = set([depId])
                else:
                    self.theoryDict[deptheory] = self.theoryDict[deptheory].union([depId])                   
                        
            # Update theoryModels
            self.theoryModels[self.currentTheory].update(features,self.currentTheory in usedtheories)
            for a in self.accessibleTheories:                
                self.theoryModels[a].update(dicts.featureDict[nameId],a in usedtheories)
        IS.close()
    
    def overwrite(self,problemId,newDependencies,dicts):
        pass
    
    def delete(self):
        pass
    
    def update(self,problemId,dicts):        
        features = dicts.featureDict[problemId]
        
        # Find the actually used theories
        tmp = [dicts.idNameDict[x] for x in dicts.dependenciesDict[problemId]]
        usedTheories = set([x.split('.')[0] for x in tmp]) 
        currentTheory = (dicts.idNameDict[problemId]).split('.')[0]       
        # Create new theory model, if there is a new theory 
        if not self.theoryDict.has_key(currentTheory):
            assert not currentTheory == self.currentTheory
            if not currentTheory == None:
                self.theoryDict[currentTheory] = []
                self.currentTheory = currentTheory
                theoryModel = singleNBClassifier()
                self.theoryModels[currentTheory] = theoryModel          
        if not len(usedTheories) == 0:
            for a in self.accessibleTheories:                
                self.theoryModels[a].update(features,a in usedTheories)   
    
    def predict(self,features,accessibles,dicts):
        """
        Predicts the relevant theories. Returns the predicted theories and a list of all accessible premises in these theories.
        """         
        # TODO: This can be made a lot faster!    
        self.accessibleTheories = []
        for x in accessibles:
            xArt = (dicts.idNameDict[x]).split('.')[0]
            self.accessibleTheories.append(xArt)
        self.accessibleTheories = set(self.accessibleTheories)
        
        # Predict Theories
        predictedTheories = [self.currentTheory]
        for a in self.accessibleTheories:
            if self.theoryModels[a].predict_sparse(features):
            #if theoryModels[a].predict(dicts.featureDict[nameId]):
                predictedTheories.append(a)
        predictedTheories = set(predictedTheories)

        # Delete accessibles in unpredicted theories
        newAcc = []
        for x in accessibles:
            xArt = (dicts.idNameDict[x]).split('.')[0]
            if xArt in predictedTheories:
                newAcc.append(x)
        return predictedTheories,newAcc
        
    def save(self,fileName):
        outStream = open(fileName, 'wb')
        dump((self.currentTheory,self.accessibleTheories,self.theoryModels,self.theoryDict),outStream)
        outStream.close()
    def load(self,fileName):
        inStream = open(fileName, 'rb')
        self.currentTheory,self.accessibleTheories,self.theoryModels,self.theoryDict = load(inStream)
        inStream.close()