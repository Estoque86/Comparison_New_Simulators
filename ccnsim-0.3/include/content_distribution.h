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
#ifndef CONTENT_DISTRIBUTION_H
#define CONTENT_DISTRIBUTION_H
#include <omnetpp.h>
#include "ccnsim.h"
#include "zipf.h"


#pragma pack(push)
#pragma pack(1)
//
//This structure is very critical in terms of space. 
//In fact, it accounts for the startup memory requirement
//of the simulator, and should be keep as small as possible.
//
//
struct file{
    info_t info;
};
#pragma pack(pop)


using namespace std;



class content_distribution : public cSimpleModule{
    protected:
		virtual void initialize();
		void handleMessage(cMessage *){;}

		//<aa>
		//<aa>This method had no input parameters before</aa>
		virtual int choose_repos(int object_index);
		virtual void initialize_repo_popularity();

		virtual void finalize_total_replica();

		#ifdef SEVERE_DEBUG
		virtual void verify_replica_number();
		#endif
		//</aa>

		//</aa> I moved the following members from private to protected </aa>
		virtual vector<int> binary_strings(int,int);
		int replicas; // <aa> The number of replicas for each object. If set to -1, the value will be ignored</aa>
		int num_repos;
		int cardF;



    public:
		void init_content();
		int *init_repos(vector<int>);
		virtual double *init_repo_prices();
		int *init_clients(vector<int>);

		static vector<file> catalog;
		static zipf_distribution zipf;

		static name_t perfile_bulk;
		static name_t stabilization_bulk; 
		static name_t cut_off;

		// <aa> repositories[i] = d means that the i-th repository 
		// is attached to node[d] </aa>
		static int  *repositories;
		static double  *repo_prices; // repo_prices[i] is the price of the i-th repo
		static int  *clients;

		//<aa>
		static int *total_replicas_p; // The number of replicas that are 
								// distributed among all the repos

		static vector<double>* repo_popularity_p; // A value is associated to each
														  // repository representing the sum
														  // of the popularity of the 
														  // contained objects
		//</aa>


    private:
		//<aa>
		vector<int> repo_strings; //It is a temporary variable used to generate content dispacement among repos
		//</aa>
		
		//INI parameters
		int num_clients;
		int nodes;
		int F;

		double alpha;
		double q;


};
#endif
