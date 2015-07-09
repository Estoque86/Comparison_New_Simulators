/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/**
 * Copyright (c) 2014,  Regents of the University of California,
 *                      Arizona Board of Regents,
 *                      Colorado State University,
 *                      University Pierre & Marie Curie, Sorbonne University,
 *                      Washington University in St. Louis,
 *                      Beijing Institute of Technology,
 *                      The University of Memphis
 *
 * This file is part of NFD (Named Data Networking Forwarding Daemon).
 * See AUTHORS.md for complete list of NFD authors and contributors.
 *
 * NFD is free software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * NFD is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * NFD, e.g., in COPYING.md file.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \author Ilya Moiseenko <http://ilyamoiseenko.com/>
 * \author Junxiao Shi <http://www.cs.arizona.edu/people/shijunxiao/>
 * \author Alexander Afanasyev <http://lasr.cs.ucla.edu/afanasyev/index.html>
 */

#include "cs-entry.hpp"
#include "core/logger.hpp"

namespace nfd {
namespace cs {

NFD_LOG_INIT("CsEntry");

Entry::Entry()
  : m_isUnsolicited(false)
{
}

void
Entry::setData(const Data& data, bool isUnsolicited)
{
  m_isUnsolicited = isUnsolicited;
  m_dataPacket = data.shared_from_this();

  updateStaleTime();
}

void
Entry::updateStaleTime()
{
  m_staleAt = time::steady_clock::now() + m_dataPacket->getFreshnessPeriod();
}

bool
Entry::isStale() const
{
  return m_staleAt < time::steady_clock::now();
}

void
Entry::reset()
{
  m_staleAt = time::steady_clock::TimePoint();
  m_dataPacket.reset();
  m_isUnsolicited = false;
}

} // namespace cs
} // namespace nfd
