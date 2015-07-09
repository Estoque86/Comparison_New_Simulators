/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer, mailto giuseppe.rossini@enst.fr)
 *    Raffaele Chiocchetti (developer, mailto raffaele.chiocchetti@gmail.com)
 *    Dario Rossi (occasional debugger, mailto dario.rossi@enst.fr)
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
#include <cmath>
#include "base_cache.h"
#include "core_layer.h"
#include "statistics.h"
#include "content_distribution.h"
#include "ccn_data_m.h"

#include "fix_policy.h"
//<aa>
#include "ideal_blind_policy.h"
#include "costaware_policy.h"
#include "ideal_costaware_policy.h"
#include "error_handling.h"
//</aa>
#include "lcd_policy.h"
#include "never_policy.h"
#include "always_policy.h"
#include "decision_policy.h"
#include "betweenness_centrality.h"
#include "prob_cache.h"

#include "ccnsim.h"


//Initialization function
void base_cache::initialize(){


    nodes      = getAncestorPar("n");
    level = getAncestorPar("level");
    cache_size = par("C");  //cache size

	decisor = NULL;

    string decision_policy = par("DS");

    //Initialize the storage policy
	double target_acceptance_ratio;
	string target_acceptance_ratio_string;

    if (decision_policy.compare("lcd")==0){
		decisor = new LCD();
    } else if (decision_policy.find("fix")==0){
		target_acceptance_ratio_string = decision_policy.substr(3);
		target_acceptance_ratio = atof( target_acceptance_ratio_string.c_str() );
		decisor = new Fix(target_acceptance_ratio);
    }
	//<aa>
	else if (decision_policy.find("ideal_blind")==0){
		decisor = new Ideal_blind(this);
    } else if (decision_policy.find("ideal_costaware")==0)
	{
		target_acceptance_ratio = 0; // I don't need this parameter
		decisor = new Ideal_costaware(target_acceptance_ratio, this );
	} else if (decision_policy.find("costaware")==0)
	{
		target_acceptance_ratio_string = decision_policy.substr( strlen("costaware") );
		target_acceptance_ratio = atof(target_acceptance_ratio_string.c_str());
		decisor = new Costaware(target_acceptance_ratio);
	}
	//</aa>
	else if (decision_policy.find("btw")==0)
	{
		double db = getAncestorPar("betweenness");
		if (fabs(db - 1)<=0.001)
			error ("Node %i betwenness not defined.",getIndex());
		decisor = new Betweenness(db);
    }else if (decision_policy.find("prob_cache")==0)
	{
		decisor = new prob_cache(cache_size);
    } else if (decision_policy.find("never")==0)
	{
		decisor = new Never();
	}
	//<aa>
    else if (decision_policy.compare("lce")==0 )
	{
		decisor = new Always();
	}

	if (decisor==NULL){
        std::stringstream ermsg; 
		ermsg<<"Decision policy \""<<decision_policy<<"\" incorrect";
	    severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
	}

	// INPUT_CHECK{
		if ( decision_policy.find("fix")==0 || 
			( decision_policy.find("costaware")==0 && !decision_policy.find("ideal_costaware")== 0 )
		){	
			if ( strlen( target_acceptance_ratio_string.c_str() ) == 0 ){
				std::stringstream ermsg; 
				ermsg<<"You forgot to insert a valid value of acceptance rate when "<<
					"specifying the decision policy. Right examples are fix0.01, costaware0.1";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}

			if (target_acceptance_ratio <0){
				std::stringstream ermsg; 
				ermsg<<"target_acceptance_ratio "<<target_acceptance_ratio<<" is not valid. "<< 				
						"target_acceptance_ratio_string="<<target_acceptance_ratio_string<<
						"; decision_policy="<<decision_policy;
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}
		}
	// }INPUT_CHECK
	//</aa>




    //Cache statistics
    //--Average
    miss = 0;
    hit = 0;

	//<aa>
	decision_yes = decision_no = 0;
	//</aa>

    //--Per file
    cache_stats = new cache_stat_entry[__file_bulk + 1];

	//<aa>
	#ifdef SEVERE_DEBUG
	initialized = true;
	#endif
	//</aa>

}

void base_cache::finish(){
    char name [30];
    sprintf ( name, "p_hit[%d]", getIndex());
    //Average hit rate
    recordScalar (name, hit * 1./(hit+miss));


    sprintf ( name, "hits[%d]", getIndex());
    recordScalar (name, hit );


    sprintf ( name, "misses[%d]", getIndex());
    recordScalar (name, miss);

	//<aa>
    sprintf ( name, "decision_yes[%d]", getIndex());
    recordScalar (name, decision_yes);

    sprintf ( name, "decision_no[%d]", getIndex());
    recordScalar (name, decision_no);

    sprintf ( name, "decision_ratio[%d]", getIndex());
	double decision_ratio = (decision_yes + decision_no == 0 ) ?
			0 : (double)decision_yes / (decision_yes + decision_no) ; 
    recordScalar (name, decision_ratio);

	decisor->finish(getIndex(), this);
	//</aa>

    //Per file hit rate
    sprintf ( name, "hit_node[%d]", getIndex());
    cOutVector hit_vector(name);
    for (uint32_t f = 1; f <= __file_bulk; f++)
        hit_vector.recordWithTimestamp(f, cache_stats[f].rate() );


}



//Base class function: a data has been received:
void base_cache::store(cMessage *in){
    if (cache_size ==0){
		//<aa>
		decision_no++;
		//</aa>
		return;
	}

    if (decisor->data_to_cache((ccn_data*)in ) ){
		//<aa>
		decision_yes++;
		//</aa>
		data_store( ( (ccn_data* ) in )->getChunk() ); //store is an interface funtion: each caching node should reimplement that function

		//<aa>
		decisor->after_insertion_action();
		//</aa>
	}
	//<aa>
	else {decision_no++; }
	//</aa>

}



//Base class function: lookup for a given data
//it wraps statistics on misses and hits
bool base_cache::lookup(chunk_t chunk ){
    bool found = false;
    name_t name = __id(chunk);

    if (data_lookup(chunk)){
	//Average cache statistics(hit)
	hit++;
	found = true;

	//Per file cache statistics(hit)
	if (name <= __file_bulk)
	    cache_stats[name].hit++;

    }else{
        found = false;

		//Average cache statistics(miss)
		miss++;
		//Per file cache statistics(miss)
		if ( name <= __file_bulk )
			cache_stats[name].miss++;
    }

    return found;

}

bool base_cache::fake_lookup(chunk_t chunk){
    return data_lookup(chunk);
}



//Clear all the statistics
void base_cache::clear_stat()
{
    hit = miss = 0; //local statistics

	//<aa>
	decision_yes = decision_no = 0;
	//</aa>
    delete cache_stats;
    cache_stats = new cache_stat_entry[__file_bulk+1];
}

//<aa>
uint32_t base_cache::get_decision_yes(){
	return decision_yes;	
}

uint32_t base_cache::get_decision_no(){
	return decision_no;
}
void base_cache::set_decision_yes(uint32_t n){
	decision_yes = n;
}
void base_cache::set_decision_no(uint32_t n){
	decision_no = n;
}

const DecisionPolicy* base_cache::get_decisor(){
	return decisor;
}

#ifdef SEVERE_DEBUG
bool base_cache::is_initialized(){
	return initialized;
}
#endif
//</aa>
