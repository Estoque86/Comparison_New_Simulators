/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/**
 * Copyright (c) 2011-2015  Regents of the University of California.
 *
 * This file is part of ndnSIM. See AUTHORS for complete list of ndnSIM authors and
 * contributors.
 *
 * ndnSIM is free software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * ndnSIM is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * ndnSIM, e.g., in COPYING.md file.  If not, see <http://www.gnu.org/licenses/>.
 **/

// ndn-simple.cpp

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/ndnSIM-module.h"

namespace ns3 {

/**
 * This scenario simulates a very simple network topology:
 *
 *
 *      +----------+     1Mbps      +--------+     1Mbps      +----------+
 *      | consumer | <------------> | router | <------------> | producer |
 *      +----------+         10ms   +--------+          10ms  +----------+
 *
 *
 * To run scenario and see what is happening, use the following command:
 *
 *     NS_LOG=ndn.Consumer:ndn.Producer ./waf --run=ndn-simple
 */

int
main(int argc, char* argv[])
{
  // setting default parameters for PointToPoint links and channels
  // Config::SetDefault("ns3::PointToPointNetDevice::DataRate", StringValue("10Mbps"));
  // Config::SetDefault("ns3::PointToPointChannel::Delay", StringValue("1ms"));
  // Config::SetDefault("ns3::DropTailQueue::MaxPackets", StringValue("100"));

  uint64_t catalogCardinality = 0;          // Estimated Content Catalog Cardinality.
  double cacheToCatalogRatio = 0.01;        // Cache to Catalog Ratio per each node.
  uint32_t lambda = 1;                      // Request rate per each client.
  double alpha = 1;                         // Zipf's Exponent
  double plateau = 0;                       // q parameter for the ZipfMandelbrot distribution
  std::string simType = "";                 // Simulation Type Description
  uint32_t simDuration = 100;
  uint32_t numReqTot = 10000;               // Total number of requests inside the simulation.

  // Read optional command-line parameters
  CommandLine cmd;
  cmd.AddValue ("catalogCardinality", "Estimated Content Catalog Cardinality.", catalogCardinality);
  cmd.AddValue ("cacheToCatalogRatio", "Cache to Catalog Ratio per each node.", cacheToCatalogRatio);
  cmd.AddValue ("lambda", "Request rate per each client.", lambda);
  cmd.AddValue ("alpha", "Zipf's Exponent", alpha);
  cmd.AddValue ("plateau", "q parameter for the ZipfMandelbrot distribution", plateau);
  cmd.AddValue ("simType", "Simulation Type Description", simType);
  cmd.AddValue ("simDuration", "Length of the simulation, in seconds.", simDuration);
  cmd.AddValue ("numReqTot", "Total number of requests during the simulation", numReqTot);

  cmd.Parse (argc, argv);

  std::string catalogCardinalityStr, lambdaStr, alphaStr, plateauStr,reqStr;
  std::stringstream ss;
  ss << catalogCardinality;
  catalogCardinalityStr = ss.str();
  ss.str("");
  ss << lambda;
  lambdaStr = ss.str();
  ss.str("");
  ss << alpha;
  alphaStr = ss.str();
  ss.str("");
  ss << plateau;
  plateauStr = ss.str();
  ss.str("");
  ss << numReqTot;
  reqStr = ss.str();
  ss.str("");


  // **********   Getting the simulation run   **********
  uint64_t simRun = SeedManager::GetRun();
  uint64_t simRunOut = simRun - 1;
  std::string simRunStr;
  ss << simRun;
  simRunStr = ss.str();
  ss.str("");

  //NS_LOG_UNCOND("M=" << catalogCardinality << "\nC=" << cacheToCatalogRatio << "\nL=" << lambda
  //     << "\nT=" << simType << "\nA=" << alpha << "\nR=" << simRun);


  // **********   Calculate the Cache Size per each cache   ***********
  uint32_t cacheSize = round((double)catalogCardinality * cacheToCatalogRatio);
  ss << cacheSize;
  std::string cacheSizeStr = ss.str();
  ss.str("");


// **********   Reading the topology   ***********
  AnnotatedTopologyReader topologyReader ("", 25);
  topologyReader.SetFileName ("src/ndnSIM/examples/topologies/topo-grid-100.txt");
  topologyReader.Read ();
  uint32_t numNodes = topologyReader.GetNodes().GetN();
  // Select a random Repo
  UniformVariable m_RngRepo (0, numNodes-1);
  uint32_t repoId = (uint32_t)round(m_RngRepo.GetValue());
  Ptr<Node> producer = topologyReader.GetNodes().Get(repoId);
  NodeContainer producers;
  producers.Add(producer);
  
  // Select 30 random Consumers
  uint32_t numConsumers = 30;
  UniformVariable m_RngConsumers (0, numNodes-1);;
  bool completeConsumers = false;
  uint32_t extractedConsumers = 0;
  uint32_t randConsumer = 0;
  std::vector<uint32_t>* consumersID = new std::vector<uint32_t>(numConsumers) ;
  for(uint32_t i=0; i<consumersID->size(); i++)
  {
    consumersID->operator[](i) = numNodes+1;
  }
  while(!completeConsumers)
  {
    bool already_extracted = false;
    while(!already_extracted)
    {
      randConsumer = (uint32_t)round(m_RngConsumers.GetValue());
      for(uint32_t i=0; i<consumersID->size(); i++)
      {
        if(consumersID->operator[](i)==randConsumer)
        {
        already_extracted = true;
        break;
        }
      }
      if(already_extracted==true)
      already_extracted = false;        // It keeps going
      else {
        if (randConsumer==repoId)
          already_extracted = false;
        else
          already_extracted = true;
      }
    }
    consumersID->operator[](extractedConsumers) = randConsumer;
    std::cout << "CHOSEN CONSUMER:\t" << consumersID->operator[](extractedConsumers) << std::endl;
    extractedConsumers = extractedConsumers + 1;
    if(extractedConsumers == consumersID->size())
    completeConsumers = true;
  }
  NodeContainer consumers;
  for(uint32_t i=0; i<consumersID->size(); i++)
  {
    Ptr<Node> nd = topologyReader.GetNodes().Get(consumersID->operator[](i));
    consumers.Add(nd);
  }
  
  // Mark the remaining caches
  NodeContainer caches;
  bool already_marked;
  for(uint32_t i=0; i<numNodes; i++)
  {
    already_marked = false;
    for(uint32_t j=0; j<consumersID->size(); j++)
    {
      if(consumersID->operator[](j)==i)
      {
        already_marked = true;
        break;
      }
    }
    if(!already_marked)
    {
      if(i!=repoId)
      {
        Ptr<Node> cNd = topologyReader.GetNodes().Get(i);
        caches.Add(cNd);
      }
    }
  } 
  
  // ***********   Install CCNx stack on all nodes   **********
  ndn::StackHelper ndnHelper;
  //ndnHelper.SetForwardingStrategy ("ns3::ndn::fw::BestRoute");
  //ndnHelper.SetDefaultRoutes(true);
  ndnHelper.SetOldContentStore("ns3::ndn::cs::Lru", "MaxSize", cacheSizeStr);
  //ndnHelper.InstallAll();
  ndnHelper.Install (caches);
  ndnHelper.Install (consumers);
  ndnHelper.Install (producers);
  
  ndn::StrategyChoiceHelper::InstallAll("/prefix", "/localhost/nfd/strategy/best-route");
  // Differentiate consumers and producers with a cache size = 0  
  //ndnHelper.SetOldContentStore("ns3::ndn::cs::Lru", "MaxSize", "0");
  //ndnHelper.Install (consumers);
  //ndnHelper.Install (producers);
  
  // **********   Installing global routing interface on all nodes   **********
  ndn::GlobalRoutingHelper ndnGlobalRoutingHelper;
  ndnGlobalRoutingHelper.InstallAll();
  // Add /prefix origins to ndn::GlobalRouter
  ndnGlobalRoutingHelper.AddOrigins("/prefix", producer);
  // Calculate and install FIBs
  ndn::GlobalRoutingHelper::CalculateRoutes();
  
  // **********   Installing Application Layer   *********
  ndn::AppHelper consumerHelper("ns3::ndn::ConsumerZipfMandelbrot");
  // Consumer will request /prefix/0, /prefix/1, ...
  consumerHelper.SetPrefix("/prefix");
  consumerHelper.SetAttribute ("Frequency", StringValue(lambdaStr)); // lambda Interest per second
  consumerHelper.SetAttribute ("NumberOfContents", StringValue (catalogCardinalityStr));
  consumerHelper.SetAttribute ("Randomize", StringValue ("exponential"));
  consumerHelper.SetAttribute ("q", StringValue (plateauStr)); // q paremeter
  consumerHelper.SetAttribute ("s", StringValue (alphaStr)); // Zipf's exponent

  consumerHelper.Install(consumers);                        // first node
  
  ndn::AppHelper producerHelper("ns3::ndn::Producer");
  // Producer will reply to all requests starting with /prefix
  producerHelper.SetPrefix("/prefix");
  producerHelper.SetAttribute("PayloadSize", StringValue("1024"));
  producerHelper.Install(producer); // last node
  
  // **********   TRACING   ***********
  std::string aggrTraceStr, csTraceStr, appTraceStr;
  ss << "logs/SIM=ndnSIM" << "_T=" << simType << "_REQ=" << numReqTot << "_M="<< catalogCardinality << "_R=" << simRunOut << "_loadTrace.txt";
  aggrTraceStr = ss.str();
  ss.str("");
  ss << "logs/SIM=ndnSIM" << "_T=" << simType << "_REQ=" << numReqTot << "_M="<< catalogCardinality << "_R=" << simRunOut << "_hitTrace.txt";
  csTraceStr = ss.str();
  ss.str("");
  ss << "logs/SIM=ndnSIM" << "_T=" << simType << "_REQ=" << numReqTot << "_M="<< catalogCardinality << "_R=" << simRunOut << "_distanceTrace.txt";
  appTraceStr = ss.str();
  ss.str("");
  
  //ndn::L3RateTracer::InstallAll(aggrTraceStr, Seconds(simDuration));
  ndn::CsTracer::InstallAll(csTraceStr, Seconds(simDuration));
  ndn::AppDelayTracer::InstallAll(appTraceStr);


  Simulator::Stop (Seconds (simDuration));

  Simulator::Run();
  Simulator::Destroy();

  return 0;
}

} // namespace ns3

int
main(int argc, char* argv[])
{
  return ns3::main(argc, argv);
}
