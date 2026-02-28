import { HeroSection } from "@/components/hero/hero-section";
import { FeaturesSection } from "@/components/sections/features-section";
import { Footer } from "@/components/sections/footer";
import { BackToTop } from "@/components/ui/back-to-top";

export default function Home() {
  return (
    <>
      <HeroSection />
      <FeaturesSection />
      <Footer />
      <BackToTop />
    </>
  );
}
