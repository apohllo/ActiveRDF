# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL

require 'active_rdf'
#require 'federation/connection_pool'

$activerdflog.info "loading Sesame adapter"


# ----- java imports and extentsions
require 'java'

StringWriter = java.io.StringWriter
FileReader = java.io.FileReader
JFile = java.io.File
URLClassLoader = java.net.URLClassLoader 
JURL = java.net.URL
JClass = java.lang.Class
JObject = java.lang.Object

# sesame specific classes: 
WrapperForSesame2 = org.activerdf.wrapper.sesame2.WrapperForSesame2
QueryLanguage = org.openrdf.querymodel.QueryLanguage
NTriplesWriter = org.openrdf.rio.ntriples.NTriplesWriter
RDFFormat = org.openrdf.rio.RDFFormat



# TODO: about this adapter
class SesameAdapter < ActiveRdfAdapter
	ConnectionPool.register_adapter(:sesame,self)

	# instantiates Sesame database
	# available parameters:
	# * :location => path to a file for persistent storing or :memory for in-memory (defaults to in-memory)
	# * :inferencing => true or false, if sesame2 rdfs inferencing is uses (defaults to true)
	def initialize(params = {})
		$activerdflog.info "initializing Sesame Adapter with params #{params.to_s}"

		@reads = true
		@writes = true
	
		# if no directory path given, we use in-memory store
    if params[:location]
      if params[:location] == :memory
        sesameLocation = nil      
      else
        sesameLocation = JFile.new(params[:location])
      end
    else
      sesameLocation = nil
    end
    
    # if no inferencing is specified, we use the sesame2 rdfs inferencing
    sesameInferencing = params[:inferencing] || nil
	
	# this will not work at the current state of jruby	
#    # fancy JRuby code so that the user does not have to set the java CLASSPATH
#    
#    this_dir = File.dirname(File.expand_path(__FILE__))
#    
#    jar1 = JFile.new(this_dir + "/../../ext/wrapper-sesame2.jar")
#    jar2 = JFile.new(this_dir + "/../../ext/openrdf-sesame-2.0-alpha4-onejar.jar")
#
#    # make an array of URL, which contains the URLs corresponding to the files
#    uris = JURL[].new(2)
#    uris[0] = jar1.toURL
#    uris[1] = jar2.toURL
#
#    # this is our custom class loader, yay!
#    @activerdfClassLoader = URLClassLoader.new(uris)
#    classWrapper = JClass.forName("org.activerdf.wrapper.sesame2.WrapperForSesame2", true, @activerdfClassLoader)    
#    @myWrapperInstance = classWrapper.new_instance 

    @myWrapperInstance = WrapperForSesame2.new

		if sesameLocation == nil
		  if sesameInferencing == nil
        @db = @myWrapperInstance.callConstructor
		  else
        @db = @myWrapperInstance.callConstructor(sesameInferencing)		  
		  end
		else
		  if sesameInferencing == nil
		    @db = @myWrapperInstance.callConstructor(sesameLocation)		  
		  else
		    @db = @myWrapperInstance.callConstructor(sesameLocation,sesameInferencing)		  
		  end
		end
		
    @valueFactory = @db.getRepository.getSail.getValueFactory

    # define the finalizer, which will call close on the sesame triple store
    # recipie for this, is from: http://wiki.rubygarden.org/Ruby/page/show/GCAndMemoryManagement
#    ObjectSpace.define_finalizer(self, SesameAdapter.create_finalizer(@db))       
	end

  # TODO: this does not work, but it is also not caused by jruby. 
#  def SesameAdapter.create_finalizer(db)
#    # we have to call close on the sesame triple store, because otherwise some of the iterators are not closed properly
#    proc { puts "die";  db.close }
#  end



	# returns the number of triples in the datastore (incl. possible duplicates)
	def size
		@db.size
	end

	# deletes all triples from datastore
	def clear
		@db.clear
	end

	# deletes triple(s,p,o,c) from datastore
	# symbol parameters match anything: delete(:s,:p,:o) will delete all triples
	# you can specify a context to limit deletion to that context: 
	# delete(:s,:p,:o, 'http://context') will delete all triples with that context
	def delete(s, p, o, c=nil)
    if s.class == RDFS::Resource then
      sesameSubject = @valueFactory.createURI(s.uri)
    elsif s == :s
      sesameSubject = nil
    else
      raise ActiveRdfError, "the Sesame Adapter tried to delete a subject which was not of type RDFS::Resource, but of type #{s.class}"
    end
    if p.class == RDFS::Resource then
      sesamePredicate = @valueFactory.createURI(p.uri)
    elsif p == :p 
      sesamePredicate = nil
    else
      raise ActiveRdfError, "the Sesame Adapter tried to delete a predicate which was not of type RDFS::Resource, but of type #{p.class}"
    end
    if o.class == RDFS::Resource then
      sesameObject = @valueFactory.createURI(o.uri)
    elsif o == :o
      sesameObject = nil
    else
      sesameObject = @valueFactory.createLiteral(o.to_s)
    end	
	
    # TODO contexts
    candidateStatements = @db.getStatements(sesameSubject, sesamePredicate, sesameObject, false)
    
    @db.remove(candidateStatements)
    
    candidateStatements.close
    return @db
	end
	
	# adds triple(s,p,o) to datastore
	# s,p must be resources, o can be primitive data or resource
	def add(s,p,o,c=nil)

    if s.class == RDFS::Resource then
      sesameSubject = @valueFactory.createURI(s.uri)
    else
      raise ActiveRdfError, "the Sesame Adapter tried to add a subject which was not of type RDFS::Resource, but of type #{s.class}"
    end
    if p.class == RDFS::Resource then
      sesamePredicate = @valueFactory.createURI(p.uri)
    else
      raise ActiveRdfError, "the Sesame Adapter tried to add a predicate which was not of type RDFS::Resource, but of type #{p.class}"
    end
    if o.class == RDFS::Resource then
      sesameObject = @valueFactory.createURI(o.uri)
    else
      sesameObject = @valueFactory.createLiteral(o.to_s)
    end

    # TODO: handle context, especially if it is null

    @db.add(sesameSubject, sesamePredicate, sesameObject)
    # for contexts, just add 4th parameter

    # TODO: do we need to handle errors from the java side ? 

    return @db
	end



  # flushing is done automatically, because we run sesame2 in autocommit mode
	def flush
		true
	end	
	# saving is done automatically, because we run sesame2 in autocommit mode
	def save
    true
  end
  
  # close the underlying sesame triple store. 
  # if not called there may be open iterators. 
  def close
    @db.close
  end

  # returns all triples in the datastore
	def dump
    # the sesame connection has an export method, which writes all explicit statements to 
    # a to a RDFHandler, which we supply, by constructing a NTriplesWriter, which writes to StringWriter, 
    # and we kindly ask that StringWriter to make a string for us. Note, you have to use stringy.to_s, 
    # somehow stringy.toString does not work. yes yes, those wacky jruby guys ;) 
    stringy = StringWriter.new
    sesameWriter = NTriplesWriter.new(stringy)
    @db.export(sesameWriter)
    return stringy.to_s
	end

	# loads triples from file in ntriples format
	def load(file)
    reader = FileReader.new(file)
    @db.add(reader, "", RDFFormat::NTRIPLES)
    
    return @db
	end

	# executes ActiveRDF query on the sesame triple store associated with this adapter
	def query(query)
	
    # we want to put the results in here
    results = []
    
    # translate the query object into a SPARQL query string
    qs = Query2SPARQL.translate(query)
    
    # evaluate the query on the sesame triple store
    # TODO: if we want to get inferred statements back we have to say so, as third boolean parameter
    tuplequeryresult = @db.evaluateTupleQuery(QueryLanguage::SPARQL, qs)

    # what are the variables of the query ?
    variables = tuplequeryresult.getBindingNames
    sizeOfVariables = variables.size

    # a solution is a binding of a variable to all entities that matched this variable in the sparql query
    solutionIterator = tuplequeryresult.iterator
    
    # the following is plainly ugly. the reason is that JRuby currently does not support
    # using iterators in the ruby way: with "each". it is possible to define "each" for java.util.Iterator
    # using JavaUtilities.extend_proxy but that fails in strange ways. this is ugly but works. 
    
    # TODO: null handling, if a value is null...
    
    # if there only was one variable, then the results array should look like this: 
    # results = [ [first Value For The Variable], [second Value], ...]
    if sizeOfVariables == 1 then
      # the counter keeps track of the number of values, so we can insert them into the results at the right position
      counter = 0 
      while solutionIterator.hasNext
        solution = solutionIterator.next
        
        temparray = []
        # get the value associated with a variable in this specific solution
        temparray[0] = convertSesame2ActiveRDF(solution.getValue(variables[0]))
        results[counter] = temparray
        counter = counter + 1
      end    
    else
    # if there is more then one variable the results array looks like this: 
    # results = [ [Value From First Solution For First Variable, Value From First Solution For Second Variable, ...],
    #             [Value From Second Solution For First Variable, Value From Second Solution for Second Variable, ...], ...]
      counter = 0
      while solutionIterator.hasNext
        solution = solutionIterator.next
        
        temparray = []
        for n in 1..sizeOfVariables
          value = convertSesame2ActiveRDF(solution.getValue(variables[n-1]))
          temparray[n-1] = value
        end   
        results[counter] = temparray
        counter = counter + 1       
      end    
    end
    
    return results
	end
	
	private
	
	# check if testee is a java subclass of reference
	def jInstanceOf(testee, reference)
    # for Java::JavaClass for a <=> b the comparison operator returns: -1 if a is subclass of b, 
    # 0 if a.jclass = b.jclass, +1 in any other case.
    isSubclass = (testee <=> reference)
    if isSubclass == -1 or isSubclass == 0
      return true
    else
      return false
    end
	end
	
	# takes a part of a sesame statement, and converts it to a RDFS::Resource if it is a URI, 
	# or to a String if it is a Literal. The assumption currently, is that we will only get stuff out of sesame, 
	# which we put in there ourselves, and currently we only put URIs or Literals there. 
	# TODO: do we need to think about handling blank nodes ? e.g. if the are part of a graph read from a file ? 
	def convertSesame2ActiveRDF(input)
    jclassURI = Java::JavaClass.for_name("org.openrdf.model.URI")
    jclassLiteral = Java::JavaClass.for_name("org.openrdf.model.Literal")	

    if jInstanceOf(input.java_class, jclassURI) 
      return RDFS::Resource.new(input.toString)
    elsif jInstanceOf(input.java_class, jclassLiteral)
      return input.toString
    else
      raise ActiveRdfError, "the Sesame Adapter tried to return something which is neither a URI nor a Literal, but is instead a #{input.java_class.name}"
    end	
	end
	
end
