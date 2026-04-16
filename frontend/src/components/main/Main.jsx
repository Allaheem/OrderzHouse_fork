import { Users, Briefcase, Handshake } from "lucide-react";

import HeroSection from './sections/Hero';
import Categories from './sections/Categories';
import Faq from './sections/Faq';
import LogoGrid from './sections/logoGrid'; 
import JoinCommunity from './sections/JoinCommunity'; 
import PageMeta from "../PageMeta.jsx";


export default function OrderzHousePageRedesign() {
  const handleSearch = () => {};

  return (
    <div className="min-h-screen bg-white" style={{ fontFamily: "'Merriweather', serif" }}>
      <PageMeta title="OrderzHouse – Freelance & Projects" description="Connect with freelancers, post projects, and manage work in one place." />
      {/* Hero Section */}
      <HeroSection onSearch={handleSearch} />
      

      {/* Categories Section */}
      <Categories />

      {/* Community Section */}
      <JoinCommunity />
      {/* FAQ Section */}
      <Faq />

      {/* ✅ LogoGrid Section */}
      <LogoGrid />
    </div>
  );
}
