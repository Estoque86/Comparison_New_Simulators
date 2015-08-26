/* -*-  Mode: C++; c-file-style: "gnu"; indent-tabs-mode:nil; -*- */
/*
 * Copyright (c) 2011-2012 University of California, Los Angeles
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * Author: Alexander Afanasyev <alexander.afanasyev@ucla.edu>
 */

// ndn-tree-cs-tracers.cc

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/ndnSIM-module.h"

using namespace ns3;

/**
 * This scenario simulates a single cache
 *
 *     /--------\      /---------\      /--------\
 *     |consumer| <--> |int_cache| <--> |producer|
 *     \--------/      \---------/      \--------/
 *
 * To run scenario and see what is happening, use the following command:
 *
 *     ./waf --run=ndn-single-cache-cs-tracers
 */

int
main (int argc, char *argv[])
{
    CommandLine cmd;
    cmd.Parse (argc, argv);
    
    AnnotatedTopologyReader topologyReader ("", 1);
    topologyReader.SetFileName ("src/ndnSIM/examples/topologies/single-cache.txt");
    topologyReader.Read ();
    
    Ptr<Node> consumer = Names::Find<Node> ("consumer");
    Ptr<Node> producer = Names::Find<Node> ("producer");
    Ptr<Node> cache = Names::Find<Node> ("int_cache");
    
    NodeContainer nonCachingNodes, cachingNodes;
    
    nonCachingNodes.Add(consumer);
    nonCachingNodes.Add(producer);
    cachingNodes.Add(cache);
    
    // Install CCNx stack on all nodes
    ndn::StackHelper ndnHelper;
    ndnHelper.SetForwardingStrategy ("ns3::ndn::fw::BestRoute");
    ndnHelper.SetContentStore ("ns3::ndn::cs::Lru", "MaxSize", "0"); // default ContentStore parameters
    ndnHelper.InstallAll();
    //ndnHelper.Install (cachingNodes);
    
    //ndnHelper.SetContentStore ("ns3::ndn::cs::Lru", "MaxSize", "0"); // Consumer and Producer do not cache anything
    //ndnHelper.Install (nonCachingNodes);
    
    // Installing global routing interface on all nodes
    ndn::GlobalRoutingHelper ccnxGlobalRoutingHelper;
    ccnxGlobalRoutingHelper.InstallAll ();
    
    // Getting containers for the consumer/producer
    //Ptr<Node> consumer = Names::Find<Node> ("consumer");
    //Ptr<Node> producer = Names::Find<Node> ("producer");
    
    //ndn::AppHelper consumerHelper ("ns3::ndn::ConsumerCbr");
    //consumerHelper.SetAttribute ("Frequency", StringValue ("10")); // 100 interests a second
    //consumerHelper.SetPrefix ("/root");
    
    ndn::AppHelper consumerHelper ("ns3::ndn::ConsumerZipfMandelbrot");
    consumerHelper.SetPrefix ("/root");
    consumerHelper.SetAttribute ("Frequency", StringValue ("10")); // 10 interests a second
    consumerHelper.SetAttribute ("NumberOfContents", StringValue ("100")); // 10 different contents
    consumerHelper.SetAttribute ("Randomize", StringValue ("none"));
    consumerHelper.SetAttribute ("q", StringValue ("0")); // q paremeter
    consumerHelper.SetAttribute ("s", StringValue ("1")); // Zipf's exponent

    
    ApplicationContainer app = consumerHelper.Install (consumer);
    app.Start (Seconds (0.0));
    
    ndn::AppHelper producerHelper ("ns3::ndn::Producer");
    producerHelper.SetAttribute ("PayloadSize", StringValue("1024"));
    
    // Register /root prefix with global routing controller and
    // install producer that will satisfy Interests in /root namespace
    ccnxGlobalRoutingHelper.AddOrigins ("/root", producer);
    producerHelper.SetPrefix ("/root");
    producerHelper.Install (producer);
    
    
    // Calculate and install FIBs
    ccnxGlobalRoutingHelper.CalculateRoutes ();
    
    Simulator::Stop (Seconds (1000.0));
    
    ndn::CsTracer::Install (cachingNodes, "cs-trace-single-cache-ZIPF-PROVA.txt", Seconds (1));
    
    Simulator::Run ();
    Simulator::Destroy ();
    
    return 0;
}
