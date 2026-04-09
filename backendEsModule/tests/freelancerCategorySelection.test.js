// Integration tests: require a running API + DB (e.g. npm run dev on port 3000).
// Run explicitly: RUN_INTEGRATION_TESTS=1 npm test
const axios = require("axios");

const testUserData = {
  role_id: 3,
  first_name: "John",
  last_name: "Doe",
  email: "info@battechno.com",
  password: "TestPass123",
  phone_number: "+1234567890",
  country: "USA",
  username: "johndoetest",
  category_id: 1,
  sub_category_ids: [2, 3],
};

const runIntegration = process.env.RUN_INTEGRATION_TESTS === "1";
(runIntegration ? describe : describe.skip)(
  "Freelancer Category Selection (integration)",
  () => {
    test("should register freelancer with category and sub-categories", async () => {
      try {
        const response = await axios.post(
          "http://localhost:3000/users/register",
          testUserData
        );
        expect(response.status).toBe(201);
        expect(response.data.success).toBe(true);
      } catch (error) {
        if (error.response && error.response.status === 409) {
          expect(error.response.status).toBe(409);
        } else {
          throw error;
        }
      }
    });

    test("should reject more than 3 sub-categories", async () => {
      const userDataWithTooManySubCategories = {
        ...testUserData,
        email: "info@battechno.com",
        username: "johndoetest2",
        sub_category_ids: [1, 2, 3, 4, 5],
      };

      try {
        await axios.post(
          "http://localhost:3000/users/register",
          userDataWithTooManySubCategories
        );
        throw new Error("Expected request to fail");
      } catch (error) {
        expect(error.response).toBeDefined();
        expect(error.response.status).toBe(400);
        expect(error.response.data.message).toContain("maximum of 3 sub-categories");
      }
    });
  }
);
