import { describe, it, expect } from "vitest";
import { deriveLabel, spansOverlap } from "./labels";

describe("deriveLabel", () => {
  it("renders a graduating student as Class of {grad year}", () => {
    expect(
      deriveLabel("student", { startYear: 2017, endYear: 2021, graduated: true }),
    ).toBe("Alum · Class of 2021");
  });

  it("renders a non-graduating student as a year range", () => {
    expect(
      deriveLabel("student", { startYear: 2017, endYear: 2021, graduated: false }),
    ).toBe("Alum · 2017–2021");
  });

  it("renders faculty with a year range", () => {
    expect(deriveLabel("faculty", { startYear: 2008, endYear: 2016 })).toBe(
      "Faculty · 2008–2016",
    );
  });

  it("renders staff with a year range", () => {
    expect(deriveLabel("staff", { startYear: 2010, endYear: 2014 })).toBe(
      "Staff · 2010–2014",
    );
  });

  it("collapses single-year spans", () => {
    expect(deriveLabel("faculty", { startYear: 2012, endYear: 2012 })).toBe(
      "Faculty · 2012",
    );
  });

  it("falls back to a role-only label with no span", () => {
    expect(deriveLabel("student", null)).toBe("Alum");
    expect(deriveLabel("staff", undefined)).toBe("Staff");
  });
});

describe("spansOverlap (era-overlap)", () => {
  it("detects intersecting spans", () => {
    expect(
      spansOverlap({ startYear: 2003, endYear: 2007 }, { startYear: 2005, endYear: 2009 }),
    ).toBe(true);
  });

  it("treats touching endpoints as overlap (same year present)", () => {
    expect(
      spansOverlap({ startYear: 2003, endYear: 2007 }, { startYear: 2007, endYear: 2011 }),
    ).toBe(true);
  });

  it("rejects disjoint spans", () => {
    expect(
      spansOverlap({ startYear: 2003, endYear: 2006 }, { startYear: 2007, endYear: 2011 }),
    ).toBe(false);
  });
});
