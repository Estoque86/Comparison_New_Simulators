/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer)
 *    Raffaele Chiocchetti (developer)
 *    Dario Rossi (occasional debugger)
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
#include "core_layer.h"
#include "ccnsim.h"
#include <algorithm>

#include "content_distribution.h"
#include "strategy_layer.h"
#include "ccn_interest.h"
#include "ccn_data.h"
#include "base_cache.h"

//<aa>
#include "error_handling.h"
//</aa>

Register_Class(core_layer);
int core_layer::repo_interest = 0;


void  core_layer::initialize(){
    RTT = par("RTT");
	//<aa>
	interest_aggregation = par("interest_aggregation");
	transparent_to_hops = par("transparent_to_hops");
	// Notice that repo_price has been initialized by WeightedContentDistribution
	//</aa>
    repo_load = 0;
    nodes = getAncestorPar("n"); //Number of nodes
    my_btw = getAncestorPar("betweenness");
    int num_repos = getAncestorPar("num_repos");

	//<aa>
	#ifdef SEVERE_DEBUG
		is_it_initialized = false;
		it_has_a_repo_attached = false;
	#endif
	//</aa>

    int i = 0;
    my_bitmask = 0;
    for (i = 0; i < num_repos; i++)
	{
		if (content_distribution::repositories[i] == getIndex() ){
			//<aa>
			#ifdef SEVERE_DEBUG
				it_has_a_repo_attached = true;
			#endif

			repo_price = content_distribution::repo_prices[i]; 
			//</aa>
			break;
		} else
				repo_price = 0;
	}
    my_bitmask = (1<<i);//recall that the width of the repository bitset is only num_repos

    //Getting the content store
    ContentStore = (base_cache *) gate("cache_port$o")->getNextGate()->getOwner();
    strategy = (strategy_layer *) gate("strategy_port$o")->getNextGate()->getOwner();

    //Statistics
    //interests = 0; //<aa> Disabled this. The reset is inside clear_stat() </aa>
    //data = 0; //<aa> Disabled this. The reset is inside clear_stat() </aa>

	//<aa>
	clear_stat();

	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);
	is_it_initialized = true;

	if (gateSize("face$o") > (int) sizeof(interface_t)*8 )
	{
		std::stringstream msg;
		msg<<"Node "<<getIndex()<<" has "<<gateSize("face$o")<<" output ports. But the maximum "
			<<"number of interfaces manageable by ccnsim is "<<sizeof(interface_t)*8 <<
			" beacause the type of "
			<<"interface_t is of size "<<sizeof(interface_t)<<" bytes. You can change the definition of "
			<<"interface_t (in ccnsim.h) to solve this issue and recompile";
		severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}
	#endif
	//</aa>

}



/*
 * Core layer core function. Here the incoming packet is classified,
 * determining if it is an interest or a data packet (the corresponding
 * counters are increased). The two auxiliar functions handle_interest() and
 * handle_data() have the task of dealing with interest and data processing.
 */
void core_layer::handleMessage(cMessage *in){
	//<aa>
	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);
	char* last_received;
	#endif
	//</aa>


    ccn_data *data_msg;
    ccn_interest *int_msg;


    int type = in->getKind();
    switch(type){
    //On receiving interest
    case CCN_I:	
		interests++;

		int_msg = (ccn_interest *) in;

		//<aa>
		if (!transparent_to_hops)
		//</aa>
			int_msg->setHops(int_msg -> getHops() + 1);

		if (int_msg->getHops() == int_msg->getTTL())
		{
	    	//<aa>
	    	#ifdef SEVERE_DEBUG
	    	discarded_interests++;
	    	check_if_correct(__LINE__);
	    	#endif
	    	//</aa>
	    	break;
		}
		int_msg->setCapacity (int_msg->getCapacity() + ContentStore->get_size());
		handle_interest (int_msg);
		break;

    //On receiving data
    case CCN_D:
		data++;

		data_msg = (ccn_data* ) in; //One hop more from the last caching node (useful for distance policy)

		//<aa>
		if (!transparent_to_hops)
		//</aa>
			data_msg->setHops(data_msg -> getHops() + 1);

		handle_data(data_msg);

		break;
    }

    delete in;
    
	//<aa>
	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);
	#endif
	//</aa>
}

//Per node statistics printing
void core_layer::finish(){
	//<aa>
	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);
//		if (	data+repo_load != \
//				(int) (ContentStore->get_decision_yes() + 
//						ContentStore->get_decision_no() ) 
//		){
//			std::stringstream msg; 
//			msg<<"node["<<getIndex()<<"]: "<<
//				"decision_yes=="<<ContentStore->get_decision_yes()<<
//				"; decision_no=="<<ContentStore->get_decision_no()<<
//				"; repo_load=="<<repo_load<<
//				"; data="<<data<<
//				". The sum of decision_yes+decision_no MUST be equal to data+repo_load";
//			severe_error(__FILE__, __LINE__, msg.str().c_str() );
//		}
	#endif
	//</aa>

    char name [30];

    //Total interests
	// <aa> Parts of these interests will be satisfied by the local cache; the remaining part will be sent to the local repo (if present) and partly sarisfied there. For the remaining part, a FIB entry will be searched to forward the intereset. If no FIB entry is found, the interest will be discarded </aa>
    sprintf ( name, "interests[%d]", getIndex());
    recordScalar (name, interests);

    if (repo_load != 0){
		sprintf ( name, "repo_load[%d]", getIndex());
		recordScalar(name,repo_load);
    }

    //Total data
    sprintf ( name, "data[%d]", getIndex());
    recordScalar (name, data);

	//<aa> Interests sent to the repository attached to this node</aa>
    if (repo_interest != 0){
	sprintf ( name, "repo_int[%d]", getIndex());
	recordScalar(name, repo_interest);
	repo_interest = 0;
    }


}




/* Handling incoming interests:
*  if an interest for a given content comes up: 
*     a) Check in your Content Store
*     b) Check if you are the source for that data. 
*     c) Put the interface within the PIT.
*/
void core_layer::handle_interest(ccn_interest *int_msg)
{
	//<aa>
	#ifdef SEVERE_DEBUG
		client* cli = __get_attached_client( int_msg->getArrivalGate()->getIndex() );
		if (cli && !cli->is_active() ) {
			std::stringstream msg; 
			msg<<"I am node "<< getIndex()<<" and I received an interest from interface "<<
				int_msg->getArrivalGate()->getIndex()<<". This is an error since there is "<<
				"a deactivated client attached there";
			debug_message(__FILE__, __LINE__, msg.str().c_str() );
		}
	#endif
	//</aa>

 
   chunk_t chunk = int_msg->getChunk();
    double int_btw = int_msg->getBtw();

    if (ContentStore->lookup(chunk)){
        //
        //a) Check in your Content Store
        //
        ccn_data* data_msg = compose_data(chunk);

        data_msg->setHops(0);
        data_msg->setBtw(int_btw); //Copy the highest betweenness
        data_msg->setTarget(getIndex());
        data_msg->setFound(true);

        data_msg->setCapacity(int_msg->getCapacity());
        data_msg->setTSI(int_msg->getHops());
        data_msg->setTSB(1);

		//<aa> I transformed send in send_data</aa>
        send_data(data_msg,"face$o", int_msg->getArrivalGate()->getIndex(), __LINE__); 
        
        //<aa>
        #ifdef SEVERE_DEBUG
        interests_satisfied_by_cache++;
		check_if_correct(__LINE__);
        #endif
        //</aa>

    } else if ( my_bitmask & __repo(int_msg->get_name() ) ){
	//
	//b) Look locally (only if you own a repository)
	// we are mimicking a message sent to the repository
	//
        ccn_data* data_msg = compose_data(chunk);
	
		//<aa>
		data_msg->setPrice(repo_price); 	// I fix in the data msg the cost of the object
										// that is the price of the repository
		//</aa>


		repo_interest++;
		repo_load++;

        data_msg->setHops(1);
        data_msg->setTarget(getIndex());
		data_msg->setBtw(std::max(my_btw,int_btw));

		data_msg->setCapacity(int_msg->getCapacity());
		data_msg->setTSI(int_msg->getHops() + 1);
		data_msg->setTSB(1);
		data_msg->setFound(true);

        ContentStore->store(data_msg);

		//<aa> I transformed send in send_data</aa>
		send_data(data_msg,"face$o",int_msg->getArrivalGate()->getIndex(),__LINE__);

		//<aa>
		#ifdef SEVERE_DEBUG
		check_if_correct(__LINE__);
		#endif
		//</aa>
   } else {
        //
        //c) Put the interface within the PIT (and follow your FIB)
        //
        
   		//<aa>
		#ifdef SEVERE_DEBUG
		unsatisfied_interests++;
		check_if_correct(__LINE__);
		#endif
		//</aa>


        unordered_map < chunk_t , pit_entry >::iterator pitIt = PIT.find(chunk);

		//<aa>
		bool i_will_forward_interest = false;
		//</aa>

		//<aa> Insert a new PIT entry for this object, if not present. If present and invalid, reset the
		// old entry. If present and valid, do nothing </aa>
        if (	
			//<aa> there is no such an entry in the PIT thus I have to forward the interest</aa>
			pitIt==PIT.end()

			//<aa> There is a PIT entry but it is invalid (the PIT entry has been invalidated by client
			// because a timer expired and the object has not been found </aa>
			|| (pitIt != PIT.end() && int_msg->getNfound() ) 

			//<aa> Too much time has been passed since the old PIT entry was added </aa>
			|| simTime() - PIT[chunk].time > 2*RTT
        ){
			//<aa> Replaces the lines
			//		bool * decision = strategy->get_decision(int_msg);
			//		handle_decision(decision,int_msg);
			// 		delete [] decision;//free memory for the decision array
			i_will_forward_interest = true;
			//</aa>

	    	if (pitIt!=PIT.end())
				PIT.erase(chunk);
			//<aa>Last time this entry has been updated is now</aa>
	    	PIT[chunk].time = simTime(); 
		}

		//<aa>
		if (int_msg->getTarget() == getIndex() )
		{	// I am the target of this interest but I have no more the object
			// Therefore, this interest cannot be aggregated with the others
			int_msg->setAggregate(false);
		}

		if ( !interest_aggregation || int_msg->getAggregate()==false )
			i_will_forward_interest = true;

		if (i_will_forward_interest)
		{  	bool * decision = strategy->get_decision(int_msg);
	    	handle_decision(decision,int_msg);
	    	delete [] decision;//free memory for the decision array
		}
		#ifdef SEVERE_DEBUG
		interface_t old_PIT_string = PIT[chunk].interfaces;
		check_if_correct(__LINE__);

		client*  c = __get_attached_client( int_msg->getArrivalGate()->getIndex() );
		if (c && !c->is_active() ){
			std::stringstream ermsg; 
			ermsg<<"Trying to add to the PIT an interface where a deactivated client is attached";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		#endif
		//</aa>


		//<aa> The following line will add the origin interface of the interest 
		//		msg to the PIT </aa>
		add_to_pit( chunk, int_msg->getArrivalGate()->getIndex() );

		//<aa>
		#ifdef SEVERE_DEBUG
		check_if_correct(__LINE__);
		#endif
		//</aa>
    }
    
    //<aa>
    #ifdef SEVERE_DEBUG
    check_if_correct(__LINE__);
    #endif
    //</aa>
}


/*
 * Handle incoming data packets. First check within the PIT if there are
 * interfaces interested for the given content, then (try to) store the object
 * within your content store. Finally propagate the interests towards all the
 * interested interfaces.
 */
void core_layer::handle_data(ccn_data *data_msg)
{
    int i = 0;
    interface_t interfaces = 0;
    chunk_t chunk = data_msg -> getChunk(); //Get information about the file

    unordered_map < chunk_t , pit_entry >::iterator pitIt = PIT.find(chunk);

	//<aa>
	#ifdef SEVERE_DEBUG
		int copies_sent = 0;
	#endif
	//</aa>


    //If someone had previously requested the data 
    if ( pitIt != PIT.end() )
	{
		ContentStore->store(data_msg);
		interfaces = (pitIt->second).interfaces;//get interface list
		i = 0;
		while (interfaces){
			if ( interfaces & 1 ){
				//<aa> I transformed send in send_data</aa>
				send_data(data_msg->dup(), "face$o", i,__LINE__ ); //follow bread crumbs back

				//<aa>
				#ifdef SEVERE_DEBUG
					copies_sent++;
				#endif
				//</aa>
			}
			i++;
			interfaces >>= 1;
		}
    } 
	//<aa> 
	// Otherwise the data are unrequested
	#ifdef SEVERE_DEBUG
		else unsolicited_data++;
	#endif


    PIT.erase(chunk); //erase pending interests for that data file

	//<aa>
	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);
	#endif
	//</aa>
}


void core_layer::handle_decision(bool* decision,ccn_interest *interest){
	//<aa>
	#ifdef SEVERE_DEBUG
	bool interest_has_been_forwarded = false;
	#endif
	//</aa>

    if (my_btw > interest->getBtw())
		interest->setBtw(my_btw);

    for (int i = 0; i < __get_outer_interfaces(); i++)
	{
		//<aa>
		#ifdef SEVERE_DEBUG
			if (decision[i] == true && __check_client(i) )
			{
				std::stringstream msg; 
				msg<<"I am node "<< getIndex()<<" and the interface supposed to give"<<
					" access to chunk "<< interest->getChunk() <<" is "<<i
					<<". This is impossible "<<
					" since that interface is to reach a client and you cannot access"
					<< " a content from a client ";
				severe_error(__FILE__, __LINE__, msg.str().c_str() );
			}
		#endif
		//</aa>

		if (decision[i] == true && !__check_client(i)
			//&& interest->getArrivalGate()->getIndex() != i
		){
			sendDelayed(interest->dup(),interest->getDelay(),"face$o",i);
			#ifdef SEVERE_DEBUG
			interest_has_been_forwarded = true;
			#endif
		}
	}
	//<aa>
	#ifdef SEVERE_DEBUG
		if (! interest_has_been_forwarded)
		{
			int affirmative_decision_from_arrival_gate = 0;
			int affirmative_decision_from_client = 0;
			int last_affermative_decision = -1;

			for (int i = 0; i < __get_outer_interfaces(); i++)
			{
				if (decision[i] == true)
				{
					if ( __check_client(i) ){
						affirmative_decision_from_client++;
						last_affermative_decision = i;
					}
					if ( interest->getArrivalGate()->getIndex() == i ){
						affirmative_decision_from_arrival_gate++;
						last_affermative_decision = i;
					}
				}
			}
			std::stringstream msg; 
			msg<<"I am node "<< getIndex()<<" and interest for chunk "<<
				interest->getChunk()<<" has not been forwarded. "<<
				". One of the possible repositories of this chunk is "<< 
				interest->get_repos()[0] <<" and the target of the interest is "<<
				interest->getTarget() <<
				". affirmative_decision_for_client = "<<
				affirmative_decision_from_client<<
				". affirmative_decision_for_arrival_gate = "<<
				affirmative_decision_from_arrival_gate<<
				". I would have sent the interest to interface "<<
				last_affermative_decision;
			severe_error(__FILE__, __LINE__, msg.str().c_str() );
		}
	#endif
}


bool core_layer::check_ownership(vector<int> repositories){
    bool check = false;
    if (find (repositories.begin(),repositories.end(),getIndex()) != repositories.end())
	check = true;
    return check;
}



/*
 * Compose a data response packet
 */
ccn_data* core_layer::compose_data(uint64_t response_data){
    ccn_data* data = new ccn_data("data",CCN_D);
    data -> setChunk (response_data);
    data -> setHops(0);
    data->setTimestamp(simTime());
    return data;
}

/*
 * Clear local statistics
 */
void core_layer::clear_stat(){
    repo_interest = 0;
    interests = 0;
    data = 0;
    
    //<aa>
    repo_interest = 0;
    repo_load = 0;
	ContentStore->set_decision_yes(0);
	ContentStore->set_decision_no(0);

    
   	#ifdef SEVERE_DEBUG
	unsolicited_data = 0;
	discarded_interests = 0;
	unsatisfied_interests = 0;
	interests_satisfied_by_cache = 0;
	check_if_correct(__LINE__);
	#endif
    //</aa>
}

//<aa>
#ifdef SEVERE_DEBUG
void core_layer::check_if_correct(int line)
{
	if (repo_load != interests - discarded_interests - unsatisfied_interests
		-interests_satisfied_by_cache)
	{
			std::stringstream msg; 
			msg<<"node["<<getIndex()<<"]: "<<
				"repo_load="<<repo_load<<"; interests="<<interests<<
				"; discarded_interests="<<discarded_interests<<
				"; unsatisfied_interests="<<unsatisfied_interests<<
				"; interests_satisfied_by_cache="<<interests_satisfied_by_cache;
		    severe_error(__FILE__, line, msg.str().c_str() );
	}

	if (!it_has_a_repo_attached && repo_load>0 )
	{
			std::stringstream msg; 
			msg<<"node["<<getIndex()<<"] has no repo attached. "<<
				"repo_load=="<<repo_load<<
				"; repo_interest=="<<repo_interest;
			severe_error(__FILE__, line, msg.str().c_str() );
	}

	if (	ContentStore->get_decision_yes() + ContentStore->get_decision_no() +  
						(unsigned) unsolicited_data
						!=  (unsigned) data + repo_load
	){
					std::stringstream ermsg; 
					ermsg<<"caches["<<getIndex()<<"]->decision_yes="<<ContentStore->get_decision_yes()<<
						"; caches[i]->decision_no="<< ContentStore->get_decision_no()<<
						"; cores[i]->data="<< data<<
						"; cores[i]->repo_load="<< repo_load<<
						"; cores[i]->unsolicited_data="<< unsolicited_data<<
						". The sum of "<< "decision_yes + decision_no + unsolicited_data must be data";
					severe_error(__FILE__,line,ermsg.str().c_str() );
	}
} //end of check_if_correct(..)
#endif
//</aa>

//<aa>
double core_layer::get_repo_price()
{
	#ifdef SEVERE_DEBUG
	if (!is_it_initialized)
	{
			std::stringstream msg; 
			msg<<"I am node "<< getIndex()<<". Someone called this method before I was"
				" initialized";
			severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}
	#endif

	return repo_price;
}

void core_layer::add_to_pit(chunk_t chunk, int gateindex)
{
	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);

	if (gateindex > gateSize("face$o")-1 )
	{
		std::stringstream msg;
		msg<<"You are inserting a pit entry related to interface "<<gateindex<<
			". But the number of ports is "<<gateSize("face$o");
		severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}

	if (gateindex > (int) sizeof(interface_t)*8-1 )
	{
		std::stringstream msg;
		msg<<"You are inserting a pit entry related to interface "<<gateindex<<
			". But the maximum interface "
			<<"number manageable by ccnsim is "<<sizeof(interface_t)*8-1 <<" beacause the type of "
			<<"interface_t is of size "<<sizeof(interface_t)<<". You can change the definition of "
			<<"interface_t (in ccnsim.h) to solve this issue and recompile";
		severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}
	#endif	

	__sface( PIT[chunk].interfaces , gateindex );

	#ifdef SEVERE_DEBUG

	unsigned long long bit_op_result = (interface_t)1 << gateindex;
	if ( bit_op_result > pow(2,gateSize("face$o")-1) )
	{
				printf("ATTTENZIONE bit_op_result %llX\n", bit_op_result);
				std::stringstream ermsg; 
				ermsg<<"I am node "<<getIndex()<<", bit_op_result="<<bit_op_result <<
					" while the number of ports is "<<
					gateSize("face$o")<<" and the max number that I should observe is "<<
					pow(2,gateSize("face$o") )-1;
				ermsg<<". (1<<34)="<< (1<<34);
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
	}

	check_if_correct(__LINE__);
	#endif
}

int	core_layer::send_data(ccn_data* msg, const char *gatename, int gateindex, int line_of_the_call)
{
	if (gateindex > gateSize("face$o")-1 )
	{
		std::stringstream msg;
		msg<<"I am node "<<getIndex() <<". Line "<<line_of_the_call<<
			" commands you to send a packet to interface "<<gateindex<<
			". But the number of ports is "<<gateSize("face$o");
		severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}

	#ifdef SEVERE_DEBUG
	if ( gateindex > (int) sizeof(interface_t)*8-1 )
	{
		std::stringstream msg;
		msg<<"You are trying to send a packet through the interface gateindex. But the maximum interface "
			<<"number manageable by ccnsim is "<<sizeof(interface_t)*8-1 <<" beacause the type of "
			<<"interface_t is of size "<<sizeof(interface_t)<<". You can change the definition of "
			<<"interface_t (in ccnsim.h) to solve this issue and recompile";
		severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}

	client* c = __get_attached_client(gateindex);
	if (c)
	{	//There is a client attached to that port
		if ( !c->is_waiting_for( msg->get_name() ) )
		{
			std::stringstream msg; 
			msg<<"I am node "<< getIndex()<<". I am sending a data to the attached client that is not "<<
				" waiting for it. This is not necessarily an error, as this data could have been "
				<<" requested by the client and the client could have retrieved it before and now"
				<<" it may be fine and not wanting the data anymore. If it is the case, "<<
				"ignore this message ";
			debug_message(__FILE__, __LINE__, msg.str().c_str() );
		}

		if ( !c->is_active() )
		{
			std::stringstream msg; 
			msg<<"I am node "<< getIndex()<<". I am sending a data to the attached client "<<
				", that is not active, "<<
				" through port "<<gateindex<<". This was commanded in line "<< line_of_the_call;
			severe_error(__FILE__, __LINE__, msg.str().c_str() );
		}
	}
	#endif
	return send (msg, gatename, gateindex);
}
//</aa>
