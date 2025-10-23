//
// seed-test-matching.ts
//
// Creates test data for the matching system
// Run with: npm run test:seed
//

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const TEST_USERS = [
  {
    id: 'user1',
    name: 'Alice Chen',
    age: 24,
    gender: 'female',
    almaMater: 'Stanford',
    bio: 'Love live music and art walks',
    city: 'Palo Alto'
  },
  {
    id: 'user2',
    name: 'Bob Smith',
    age: 26,
    gender: 'male',
    almaMater: 'Stanford',
    bio: 'Into indie music and coffee',
    city: 'Palo Alto'
  },
  {
    id: 'user3',
    name: 'Carol Lee',
    age: 23,
    gender: 'female',
    almaMater: 'Berkeley',
    bio: 'Adventurous and outgoing',
    city: 'SF'
  },
  {
    id: 'user4',
    name: 'David Park',
    age: 28,
    gender: 'male',
    almaMater: 'Stanford',
    bio: 'Looking for art and dinner buddies',
    city: 'Palo Alto'
  },
  {
    id: 'user5',
    name: 'Emma Wilson',
    age: 25,
    gender: 'female',
    almaMater: 'Berkeley',
    bio: 'Low-key coffee dates',
    city: 'SF'
  }
];

const SURVEY_TEMPLATES = [
  {
    alumni_network: 'Stanford',
    age_band: '21-24',
    city: 'Palo Alto',
    availability: ['Sat evening', 'Sun daytime'],
    activities: ['Live music', 'Art walk'],
    vibe: ['Outgoing'],
    dealbreakers: ['Under 21']
  },
  {
    alumni_network: 'Stanford',
    age_band: '25-28',
    city: 'Palo Alto',
    availability: ['Sat evening'],
    activities: ['Live music', 'Coffee'],
    vibe: ['Low-key'],
    dealbreakers: []
  },
  {
    alumni_network: 'Berkeley',
    age_band: '21-24',
    city: 'SF',
    availability: ['Fri evening', 'Sat daytime'],
    activities: ['Outdoors', 'Coffee'],
    vibe: ['Adventurous'],
    dealbreakers: ['Smoking']
  },
  {
    alumni_network: 'Stanford',
    age_band: '25-28',
    city: 'Palo Alto',
    availability: ['Sat evening'],
    activities: ['Art walk', 'Dinner'],
    vibe: ['Outgoing', 'Intellectual'],
    dealbreakers: []
  },
  {
    alumni_network: 'Berkeley',
    age_band: '25-28',
    city: 'SF',
    availability: ['Fri evening'],
    activities: ['Coffee'],
    vibe: ['Low-key'],
    dealbreakers: ['Smoking']
  }
];

async function main() {
  console.log('🌱 Seeding test data for matching system...\n');
  
  // Clean up existing test data
  console.log('🗑️  Cleaning up existing test data...');
  await prisma.match.deleteMany({
    where: {
      members: {
        some: {
          userId: { in: TEST_USERS.map(u => u.id) }
        }
      }
    }
  });
  
  await prisma.poolEntry.deleteMany({
    where: {
      intention: {
        userId: { in: TEST_USERS.map(u => u.id) }
      }
    }
  });
  
  await prisma.intention.deleteMany({
    where: {
      userId: { in: TEST_USERS.map(u => u.id) }
    }
  });
  
  await prisma.surveyResponse.deleteMany({
    where: {
      userId: { in: TEST_USERS.map(u => u.id) }
    }
  });
  
  await prisma.userProfile.deleteMany({
    where: {
      userId: { in: TEST_USERS.map(u => u.id) }
    }
  });
  
  await prisma.user.deleteMany({
    where: {
      id: { in: TEST_USERS.map(u => u.id) }
    }
  });
  
  console.log('✅ Cleanup complete\n');
  
  // Create test users
  console.log('👥 Creating test users...');
  for (const userData of TEST_USERS) {
    const user = await prisma.user.create({
      data: {
        id: userData.id,
        name: userData.name,
        phone: `+1555000${TEST_USERS.indexOf(userData) + 1}000`, // Fake phone number
        verified: true,
        onboarding: false,
        profile: {
          create: {
            age: userData.age,
            gender: userData.gender,
            almaMater: userData.almaMater,
            bio: userData.bio,
            city: userData.city
          }
        }
      }
    });
    console.log(`  ✅ Created user: ${user.name} (${user.id})`);
  }
  
  console.log('\n📝 Creating survey responses...');
  for (let i = 0; i < TEST_USERS.length; i++) {
    const userId = TEST_USERS[i].id;
    const template = SURVEY_TEMPLATES[i];
    
    // Alumni network
    await prisma.surveyResponse.create({
      data: {
        userId,
        questionId: 'alumni_network',
        value: template.alumni_network,
        isMustHave: true
      }
    });
    
    // Age band
    await prisma.surveyResponse.create({
      data: {
        userId,
        questionId: 'age_band',
        value: template.age_band,
        isMustHave: false
      }
    });
    
    // City
    await prisma.surveyResponse.create({
      data: {
        userId,
        questionId: 'city',
        value: template.city,
        isMustHave: true
      }
    });
    
    // Availability
    await prisma.surveyResponse.create({
      data: {
        userId,
        questionId: 'availability',
        value: template.availability,
        isMustHave: true
      }
    });
    
    // Activities
    await prisma.surveyResponse.create({
      data: {
        userId,
        questionId: 'activities',
        value: template.activities,
        isMustHave: false
      }
    });
    
    // Vibe
    await prisma.surveyResponse.create({
      data: {
        userId,
        questionId: 'vibe',
        value: template.vibe,
        isMustHave: false
      }
    });
    
    // Dealbreakers
    await prisma.surveyResponse.create({
      data: {
        userId,
        questionId: 'dealbreakers',
        value: template.dealbreakers,
        isMustHave: false
      }
    });
    
    console.log(`  ✅ Created survey for: ${TEST_USERS[i].name}`);
  }
  
  console.log('\n💭 Creating intentions...');
  for (let i = 0; i < TEST_USERS.length; i++) {
    const userId = TEST_USERS[i].id;
    const template = SURVEY_TEMPLATES[i];
    
    const chips = {
      who: {
        network: template.alumni_network,
        ageBand: template.age_band,
        genderPref: 'any'
      },
      what: {
        activities: template.activities,
        notes: 'Looking for good vibes'
      },
      when: template.availability,
      where: template.city,
      vibe: template.vibe,
      mustHaves: ['where', 'when'],
      dealbreakers: template.dealbreakers
    };
    
    const text = `${template.activities.join(' or ')} ${template.availability.join(' or ')} in ${template.city}`;
    
    const intention = await prisma.intention.create({
      data: {
        userId,
        text,
        parsedJson: chips,
        validFrom: new Date(),
        validUntil: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days
        status: 'active'
      }
    });
    
    // Add to pool
    await prisma.poolEntry.create({
      data: {
        intentionId: intention.id,
        tier: 0,
        joinedAt: new Date(),
        lastBatchAt: new Date()
      }
    });
    
    console.log(`  ✅ Created intention for: ${TEST_USERS[i].name}`);
  }
  
  console.log('\n✅ Test data seeded successfully!');
  console.log('\n📊 Summary:');
  console.log(`  - ${TEST_USERS.length} users created`);
  console.log(`  - ${TEST_USERS.length * 7} survey responses created`);
  console.log(`  - ${TEST_USERS.length} intentions created`);
  console.log(`  - ${TEST_USERS.length} pool entries created`);
  console.log('\n🚀 Ready to run batch matcher!');
  console.log('   Run: npm run matcher:run\n');
}

main()
  .catch((error) => {
    console.error('❌ Error seeding data:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

